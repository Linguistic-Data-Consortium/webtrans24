class RevController < ApplicationController
  before_action :authenticate
  skip_before_action :verify_authenticity_token

  def rev
    r = if params['url']
      submit_job(audio: params['url'])
    elsif params['id']
      get_transcript(id: params['id'])
    else
      { status: 'failed' }
    end
    respond_to do |format|
      format.json do
        render json: r
      end
    end
  end

  def token
    ENV['REV_TOKEN']
  end

  def list_jobs
    url = URI('https://api.rev.ai/speechtotext/v1/jobs')
    params = {
      limit: '100',
      starting_after: ''
    }
    url.query = URI.encode_www_form(params)
    
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    
    request = Net::HTTP::Get.new(url)
    request['Authorization'] = "Bearer #{token}"
    
    response = http.request(request)
    r = response.read_body
  end

  def submit_job(audio:)
    url = URI('https://api.rev.ai/speechtotext/v1/jobs')
    
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(url)
    request['Content-Type'] = 'application/json'
    request['Authorization'] = "Bearer #{token}"
    request.body = {
      metadata: 'example metadata',
      # notification_config: {
      #   url: 'https://www.example.com/callback',
      #   auth_headers: {
      #     Authorization: 'Bearer <notification-url-token>'
      #   }
      # },
      source_config: {
        url: audio
        # auth_headers: {
        #   Authorization: 'Bearer <source-url-token>'
        # }
      },
      transcriber: 'fusion',
      diarization_type: "premium",
      forced_alignment: true,
      # speaker_channel_count: 1,
      # delete_after_seconds: 2592000,
      language: 'en'
    }.to_json
    
    response = http.request(request)
    x = response.read_body
    # puts x
    x
  end

  def get_job(id:)
    url = URI('https://api.rev.ai/speechtotext/v1/jobs/' + id)
    
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    
    request = Net::HTTP::Get.new(url)
    request['Authorization'] = "Bearer #{token}"
    
    response = http.request(request)
    x = response.read_body
    # puts x
    x
  end

  def get_transcript(id:)
    url = URI('https://api.rev.ai/speechtotext/v1/jobs/' + id + '/transcript')
    params = {
      # group_channels_by: 'speaker',
      # group_channels_threshold_ms: '100'
    }
    url.query = URI.encode_www_form(params)

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(url)
    request['Accept'] = 'application/vnd.rev.transcript.v1.0+json'
    request['Authorization'] = "Bearer #{token}"

    response = http.request(request)
    x = response.read_body
    # puts x
    convert JSON.parse x
    @segments
  end

  def set_header(x)
    @header_array = x
    @header_string = @header_array.join "\t"
  end

  def convert(object)
    @segments = []
    @fn = ''
    if object['monologues'] # assume rev
      # @format = :rev
      raise "the file name must be set" if @fn.nil?
      set_header %w[ file beg end text speaker ]
      # @header ||= %w[ file beg end text speaker ]
      object['monologues'].each do |m|
        speaker = m['speaker']
        m['elements'].each do |e|
          s = {}
          if e['type'] == 'text'
            s = {
              file: @fn,
              beg: e['ts'],
              end: e['end_ts'],
              text: e['value'],
              speaker: speaker.to_s
            }
            @segments << s
          end
        end#.flatten.map { |x| norm x }
      end
    end
    @segments
  end

end

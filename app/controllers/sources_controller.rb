class SourcesController < ApplicationController

  include SourcesHelper

  skip_before_action :verify_authenticity_token, only: [ :create ]
  before_action :authenticate, except: [ :uget_public ]

  def new
    @source = Source.new
    respond_to do |format|
      format.html do
        render partial: 'new'
      end
    end
  end

  def get_upload
    @source = Source.new
    @task_id = params[:task_id]
    @project = Project.find params[:project_id] if params[:project_id]
    @task = Task.find params[:task_id] if @task_id and @task_id.to_i > 0
    @data_set = DataSet.find params[:data_set_id] if params[:data_set_id]
    respond_to do |format|
      format.html do
        render partial: 'upload'
      end
      format.json do
        partial = params[:partial] || 'upload'
        html = render_to_string(:partial => partial)
        render json: { html: html }
      end
    end
  end

  def create
    source = Source.create!(nvparams)
    source.update(uid: source&.file&.blob.key) if source.uid.nil?
    source.update(user_id: current_user.id)
    # source = Source.last
    respond_to do |format|
      format.html do
        redirect_to root_path
      end
      format.json do
        render json: source
      end
    end
  end

  def get_download
    @source = Source.find params[:id]
    respond_to do |format|
      format.html do
        render partial: 'download'
      end
    end
  end

  def nvparams
    params.require(:source).permit(:uid, :file, :task_id)
  end

end


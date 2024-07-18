class Kit < ActiveRecord::Base
  # attr_accessible :meta, :user_id, :task_id, :kit_type_id, :uid, :state, :source, :broken_comment, :tree_id
  # attr_accessible :kit_batch_id, :not_user_id, :time_spent
  belongs_to :tree, optional: true
  belongs_to :user, optional: true
  belongs_to :task, optional: true
  belongs_to :kit_type, :class_name => 'KitType', optional: true
  belongs_to :kit_batch, optional: true
  belongs_to :not_user, :class_name => 'User', optional: true
  has_many :kit_stats
  has_many :kit_values
  has_many :kit_states
  delegate :nodes, :to => :tree, :prefix => true
  delegate :name, :to => :user, :prefix => true

  # serialize :meta, Hash
  serialize :source, Hash

  scope :assigned_by_task, lambda { |t| where( :state => 'assigned', :task_id => t ) }
  scope :unassigned_by_task, lambda { |t| where( :state => 'unassigned', :task_id => t ) }
  scope :unassigned_by_task_and_user, lambda { |t, u| where( :state => 'unassigned', :task_id => t, :user_id => u ) }
  scope :find_by_task, lambda { |task_id| where :task_id => task_id }

  # attr_accessor :source_type, :source_uid

  def editor
    meta['editor']
  end
  def editor=(arg)
    meta['editor'] = arg
  end

  @@counter = "0" * 16

  def meta
    @meta ||= {}
    @meta
  end

  [ :js, :source_transform, :unmapped_infoboxes, :root, :type,
    :workflow_id, :read_only, :parent, :task_user_id, :quality_control, :update_root, :view,
    :namestring, :es_kit, :existing_slots, :refdoc, :review, :lang, :slot, :query, :speaker,
    :empty_list, :coref_groups, :bootstrap_mode ].each do |sym|
    eval "def #{sym}; meta['#{sym}']; end;"
    eval "def #{sym}=(x); meta['#{sym}'] = x; end;"
  end



  after_save :goto_state

  def goto_state
    last = kit_states.last
    if last.nil? or last.state != state
      KitState.create(kit_id: id, state: state)
      task.workflow.after_done self if state == 'done' and kit_states.where(state: :done).count == 1
    end
  end

  def to_segmentation
    if source['type'] == 'audio'
      tree.tree.to_segmentation source['id']
    elsif source['parent'].class == Hash and source['parent']['type'] == 'audio'
      tree.tree.to_segmentation source['parent']['id']
    else
      raise 'bad source for segmentation'
    end
  end

  def kbptype
    meta['type']
  end

  def kbptype=(type)
    meta['type'] = type
  end

  def assign_id
    uid = ("%x" % Time.now.to_i) + @@counter.succ!
    while Kit.find_by_uid(uid)
      uid = ("%x" % Time.now.to_i) + @@counter.succ!
    end
    uid
  end

  def requeue
    Kit.transaction do
      reload
      if state == 'unassigned'
        update( uid: assign_id )
      end
    end
  end

  def initialize(*args)
    super
    self.uid = assign_id
  end

  def self.from_hash(h)
    kit = Kit.new
    case h['type']
    when /(person|gpe|org)/
      kit.kbptype = $1
      kit.fields_from_hash h, [ :namestring, :es_kit, :existing_slots, :refdoc, :unmapped_infoboxes, :slot, :query ]
      kit
    end

    kit.from_hash h unless kit.class == Kit

    #hack for kbp assessment
    kit.fields_from_hash h, [ :entity_slot, :slot, :query  ] if h['task_id'] == 75

    kit.id = h['_id']

    kit.fields_from_hash h, [ :tree, :state, :kit_type_id, :js, :root, :task_id, :user_id, :broken_comment,
                              :empty_list, :coref_groups, :type, :source_transform, :bootstrap_mode  ]

    #adding support for document display in legacy tools that used docid for the source
    if h.include? 'docid'
      kit.source = { 'type' => 'document', 'transform' => false, 'id' => h['docid'], 'media' => 'text' }
    else
      kit.source = h['source']
    end
    kit
  end

    # change to to to_interchange?
    def to_hash(mongo=false, depth='shallow', test=false)
      # return { refresh: true }
      h = {}
      h['_id'] = uid unless uid.nil?
      if tree_id
        if mongo
          h['tree'] = tree.uid
          if h['tree'].class == String and h['tree'].length == 0
            h.delete 'tree'
          end
        else
          if tree.version > 0
            h['tree'] = { meta: { id: '0' } }
            h['xlass_def_id'] = tree.class_def_id
            h['original_id'] = tree.version
            h['def'] = { classes: {} }
            NodeList.where(class_def_id: tree.xlass_def.id).each do |nl|
              h['def'][:classes][nl.name] = { children: nl.children.split }
            end
            nodes = Xode.includes(:node_value).where(tree_id: tree_id)
            h['nodes'] = nodes.to_a
            h['node_values'] = nodes.map(&:node_value).uniq.compact.to_a.map do |x|
              {
                id: x.id,
                value: x.value,
                docid: x.docid,
                beg: (x.begi || x.begr.to_f),
                end: (x.endi || x.endr.to_f),
                text: x.text,
                source_id: x.source_id
              }
            end
            # h['last_iid'] = tree.last_iid
            xnn = Xnnotation.where(tree_id: tree_id, message: 'add').order('id desc').first
            if xnn
              h['last_iid'] = XodeValue.find(xnn.node_value_id).value.split(',').last.split(':').first.to_i
            else
              h['last_iid'] = 0
            end
          else
          h['tree'] = tree.tree.to_client_hash
          h['last_iid'] = tree.last_iid.to_i
          # class_def = tree.class_def
          nc = NodeClass.where(name: "#{class_def.name}:#{uid}").first
          if nc
            nc.constraints['edit'] ||= {}
            nc.constraints['edit']['inverted_grammar'] ||= class_def.inverted_grammar
            nc.save
            h['edit'] = nc.constraints['edit']
          end
          h['inverted_grammar'] = class_def.inverted_grammar
          h['constraints'] = class_def.constraints if tree.respond_to? 'class_def'
          h['node_classes'] = {}
          class_def.node_classes.each do |nc|
            h['node_classes'][nc.id] = {}
            h['node_classes'][nc.id]['name'] = nc.name
            h['node_classes'][nc.id]['value'] = nc.value
            # raise StyleConnectionError, "missing style? node_type.id: #{nc.id}, node_type.name: #{nc.name}" if nc.style_id.nil?
            # h['node_classes'][nc.id]['tag'] = nc.style.tag
          end
          end
        end
      end

      if depth == 'deep'
        #when a source exists, get the content and the metadata from the uget server with access to that content
        case source
        when Hash
          case source['type']
          when 'multi_post'
            file = LDC::Resources::WebMultiPost.find_by_uid(source['uid']).raw_text
            media = source['media'] ? source['media'] : 'normal'
            source.merge! LDCI::Document.new(source['id'], file, source['transform'], media).get_hash
            source['type'] = source[:type] = 'multi_post'
          when 'document'
            file = LDCI.uget( { :uid =>  source['id'], :type => source['type'], :level => 1 }.to_json )['string']
            media = source['media'] ? source['media'] : 'normal'
            source.merge! LDCI::Document.new(source['id'], file, source['transform'], media).get_hash
          when 'conversation'
            begin
              file = LDCI.uget( { :id =>  source['id'], :type => source['type'], :transform_message_content => source['transform'] }.to_json )
              source.merge! file
            rescue JSON::ParserError
              puts "Failed to parse JSON returned from uget for input: #{h['source']}"
            end
          end
        end
      end


      # h['source'] = {
      #   'id' => KitValue.where(kit_id: self.id, key: 'source_uid').first.value,
      #   # 'transform' => source['transform'], #"false",
      #   # 'media' => source['media'], #'text',
      #   'type' => KitValue.where(kit_id: self.id, key: 'source_type').first.value
      # }
      s = if source[:uid]

        Source.where(uid: source[:uid]).first
      elsif source[:id]
        Source.where(id: source[:id]).first
      else
        nil
      end
      h['source'] = if s
        { uid: s.uid, id: s.uid }
      elsif source_uid
        { uid: source_uid, id: source_uid }
      else
        {}
      end
      h['filename'] = source[:filename] if source[:filename]
      

      atts = [ :js, :source_transform, :kit_type_id, :broken_comment, :task_id, :root, :workflow_id, :read_only, :parent,
               :task_user_id, :quality_control, :state, :view, :meta, :done_comment ]

      h['type'] = case kbptype
                  when /(person|org|gpe)/
                    atts.concat [ :namestring, :es_kit, :existing_slots, :refdoc, :unmapped_infoboxes ]
                    kbptype
                  end
      atts.concat [ :empty_list, :coref_groups, :user_id ] # :update_root, :kit_type, :lang, :review
      h.delete 'type' if h['type'].nil?
      atts.concat [ :slot, :query ] if task_id == 75
      atts << :bootstrap_mode
      atts.each do |sym|
        eval "h['#{sym}'] = #{sym} unless #{sym}.nil?\n"

#        :query, :source, :bootstrap_mode ].each do |sym|
      end
      # but why?
      # ann = Annotation.where(kit_id: id).last
      # h['last_annotation_time'] = ann ? ann.created_at.to_i * 1000 : false
      time = Kit.connection.exec_query("select max(created_at) from annotations where kit_id = #{id}").entries.first['max']
      h['task_name'] = task.name
      h['last_annotation_time'] = time ? time.to_i * 1000 : false
      h['data_set_id'] = task.data_set_id
      h['kit_id'] = id
      if tree.respond_to? 'class_def'
        if class_def.class == XlassDef
          h['constraints'] = {}
        else
          h['constraints'] = class_def.constraints
        end
      end
      h
    end

    def to_simple_hash
      # return { refresh: true }
      h = {}
      h['_id'] = uid unless uid.nil?

      s = if source[:uid]

        Source.where(uid: source[:uid]).first
      elsif source[:id]
        Source.where(id: source[:id]).first
      else
        nil
      end
      h['source'] = if s
        { uid: s.uid, id: s.uid }
      elsif source_uid
        { uid: source_uid, id: source_uid }
      else
        {}
      end
      h['filename'] = source[:filename] if source[:filename]
      

      atts = [ :kit_type_id, :broken_comment, :task_id, :root, :workflow_id, :read_only, :parent,
               :task_user_id, :state, :view, :meta, :done_comment, :user_id ]

      atts.each do |sym|
        eval "h['#{sym}'] = #{sym} unless #{sym}.nil?\n"

#        :query, :source, :bootstrap_mode ].each do |sym|
      end
      # but why?
      # ann = Annotation.where(kit_id: id).last
      # h['last_annotation_time'] = ann ? ann.created_at.to_i * 1000 : false
      time = Kit.connection.exec_query("select max(created_at) from annotations where kit_id = #{id}").entries.first['max']
      h['last_annotation_time'] = time ? time.to_i * 1000 : false
      h['data_set_id'] = task.data_set_id
      h['kit_id'] = id
      h
    end

    def transcript(all_nodes)
      t = tree.create_tree_sql2(all_nodes).to_client_hash
      {
        kit_uid: uid,
        # segments: (tree ? transcript_segments(tree) : []),
        # sections: (tree ? transcript_sections(tree): [])
        segments: transcript_segments(t),
        sections: transcript_sections(t)
      }
    end

    def transcript_segments(tree)
      tree['SegmentList']['children'].map { |x|
        {
          docid: x['Segment']['value'][:docid],
          beg: x['Segment']['value'][:beg],
          end: x['Segment']['value'][:end],
          text: (x['Transcription']['value'][:value] or ''),
          speaker: (x['Speaker']['value'][:value] or '')
        }
      }
    end
    
    def transcript_sections(tree)
      return [] if tree['SectionList'].nil?
      tree['SectionList']['children'].map { |x|
        {
          section: x['Section']['value'][:value],
          beg_seg: x['BegSeg']['value'][:value],
          end_seg: x['EndSeg']['value'][:value]
        }
      }
    end
    
  def fields_from_hash(h, fields)
    h.each_key do |attr|
      raise RuntimeError, "Hash key #{attr} is not a string" if attr != attr.to_s
    end
    fields.each do |sym|
      eval "self.#{sym} = h['#{sym}']"
    end
    self
  end

  def reset
    tree_oid = nil
    @tree = nil
  end

  def blocked_for_user_id?(user_id)
    KitUser.where( kit_id: id, user_id: user_id ).count > 0
  end

  def create_tree(task_user)
    root = kit_type.new_root self, task_user
    if root.class == Tree
      update( tree_id: root.id )
    else
      update( tree_id: root.tree_id )
    end
  end

  def create_tree2(task_user:, source_kit:)
    source_kit_id = source_kit.id
    source_kit_ids = []
    while source_kit_id
      if source_kit_id.in? source_kit_ids # shouldn't be circular, but just in case
        source_kit_id = nil
      else
        source_kit_ids << source_kit_id
        source_kit_id = Kit.where(id: source_kit_id).first&.orig_id
      end
    end
    cd = class_def
    if cd.class == XlassDef
      ids = Xnnotation.where(kit_id: source_kit_ids).pluck(:transaction_id)
      j = XnnotationJournal.where(id: ids).order(:id)
      root = kit_type.new_root2 kit: self, task_user: task_user, journals: j
      update( tree_id: root.id )
    else
      ids = Annotation.where(kit_id: source_kit_ids).pluck(:transaction_id)
      j = AnnotationJournal.where(id: ids).order(:id)
      root = kit_type.new_root2 kit: self, task_user: task_user, journals: j
      update( tree_id: root.tree_id )
    end
    KitValue.create(kit_id: id, key: :source_kit, value: source_kit.id)
  end

  def class_def
    XlassDef.find_by_name 'ArcTranscription'
  end

  def convertx
    xnns = Xnnotation.where(kit_id: id)
    XnnotationJournal.where(id: xnns.pluck(:transaction_id)).destroy_all
    xnns.destroy_all
    Xode.where(tree_id: tree_id).destroy_all
    journals = AnnotationJournal.where(id: Annotation.where(kit_id: id).pluck(:transaction_id)).to_a.sort_by { |x| x.id }
    check_for_asr = nil
    journals.each_with_index do |j, i|
      # special check for repeat segmentation
      if i == 1
        check_for_asr = j.json.sub /client_time.+/, ''
      else
        next if j.json.length > 10000 and check_for_asr == j.json.sub(/client_time.+/, '')
      end
      j.convertx
    end
  end

  def converty
    xnns = Xnnotation.where(kit_id: id)
    XnnotationJournal.where(id: xnns.pluck(:transaction_id)).destroy_all
    xnns.destroy_all
    Xode.where(tree_id: tree_id).destroy_all
    nodes = {}
    Node.where(tree_id: tree_id, current: true).each do |x|
      nodes[x.id] = x
    end
    items = nodes.values.select { |x| x.current and %w[ SegmentListItem SectionListItem ].include? x.name }.sort_by(&:id)
    node_values = {}
    NodeValue.where(id: nodes.values.map(&:node_value_id).select { |x| x > 0 }).each do |x|
      node_values[x.id] = x
    end
    items.each do |x|
      item = [ x ] + nodes.values.select { |y| y.parent_id == x.id }
      v = item.sort_by { |x| x.iid }.map { |x| [ x.iid, x.name ].join(':') }.join(',')
      njs = { 'messages' => [] }
      njs['messages'] << {
        node: 0,
        message: 'add',
        value: { value: v }
      }
      item.select { |x| x.node_value_id > 0 }.each do |x|
        v = node_values[x.node_value_id]
        v = if v.value
          { value: v.value }
        else
          { docid: v.docid, beg: v.begr.to_f, end: v.endr.to_f }
        end
        njs['messages'] << {
          node: x.iid,
          message: 'change',
          value: v
        }
      end
      XnnotationJournal.create(
        user_id: user_id,
        task_id: task_id,
        kit_id: id,
        tree_id: tree_id,
        json: njs
      )
    end
  end


  def convertz
    convertz_destroy # clear previous
    convertz_nodes # fill @convertz_nodes
    items = convertz_select(%w[ SegmentListItem ]) + convertz_select(%w[ SectionListItem ])
    convertz_node_values # fill @convertz_node_values
    convertz_set_other_vars
    items.each do |x|
      @njs = { 'messages' => [] }
      @bad = false
      convertz_item x # fill @njs
      convertz_item_create # create XnnotationJournal from @njs
    end
  end

  def convertz_destroy
    xnns = Xnnotation.where(kit_id: id)
    XnnotationJournal.where(id: xnns.pluck(:transaction_id)).destroy_all
    xnns.destroy_all
    Xode.where(tree_id: tree_id).destroy_all
  end

  def convertz_nodes
    @convertz_nodes = {}
    empty_items = []
    Node.where(tree_id: tree_id, current: true).each do |x|
      @convertz_nodes[x.id] = x
      empty_items << x.parent_id if (x.name == 'Segment' or x.name == 'Section') and x.node_value_id == 0
    end
    empty_items.each { |x| @convertz_nodes.delete x }
    nil
  end

  def convertz_select(a)
    @convertz_nodes.values.select { |x| x.current and a.include? x.name }.sort_by(&:id)
  end

  def convertz_node_values
    @convertz_node_values = {}
    NodeValue.where(id: @convertz_nodes.values.map(&:node_value_id).select { |x| x > 0 }).each do |x|
      @convertz_node_values[x.id] = x
    end
    nil
  end

  def convertz_set_other_vars
    @convertz_iid = 1;
    @convertz_iidmap = {}
  end

  def convertz_item(x)
    name = x.name
    if name == 'SegmentListItem'
      convertz_item_segmentlistitem
    else
      convertz_item_sectionlistitem
    end
    # arc = { iid: iid }
    # iidmap[x.iid] = arc
    item = [ x ] + @convertz_nodes.values.select { |y| y.parent_id == x.id }.sort_by(&:iid)
    convertz_addv name, item
    item.select { |x| x.node_value_id > 0 }.each do |x|
      convertz_item_children x
    end
  end

  def convertz_item_segmentlistitem
    addi = @njs['messages'].length
    (0..1).to_a.each do |i|
      iid = @convertz_iid
      @njs['messages'][addi+i]   = { node: 0, message: 'add', value: { value: "#{iid}:NListItem,#{iid+1}:N" } }
      @njs['messages'][addi+4+i] = { node: iid + 1, message: 'change' }
      @convertz_iid += 2
    end
  end

  def convertz_item_sectionlistitem
    @convertz_section = {}
  end

  def convertz_addv(name, item)
    iid = @convertz_iid
    v = item.sort_by { |x| x.iid }.map.with_index { |x, i| [ iid + i, x.name ] }
    v[1][1] = 'Arc'
    addi = @njs['messages'].length
    if name == 'SectionListItem'
      v.pop
      v[2][1] = 'Name'
    else
      v[2][1] = 'Text'
      addi -= 4
    end
    @convertz_iid += v.length
    v = v.map { |x| x.join(':') }.join(',')
    @njs['messages'][addi]   = { node: 0, message: 'add', value: { value: v } }
    @njs['messages'][addi+1] = { node: iid+1, message: 'change' }
  end

  # def convertz_item_childrenv(x)
  #   v = @convertz_node_values[x.node_value_id]
  #   if v.value
  #     v = { value: v.value }
  #   else
  #     @njs['messages'][1][:value] = { docid: v.docid, beg: v.begr.to_f, type: 'real' }
  #     @njs['messages'][3][:value] = { docid: v.docid, beg: v.endr.to_f, type: 'real' }
  #     arc[:beg] = iid - 7
  #     arc[:end] = iid - 5
  #     v = { beg: iid-7, end: iid-5 }
  #   end
  # end

  def convertz_item_children(x)
    case x.name
    when 'Segment'
      convertz_item_segment x
    when 'Transcription'
      convertz_item_transcription x
    when 'Speaker'
      convertz_item_speaker x
    when 'Section'
      convertz_item_section x
    when 'BegSeg'
      convertz_item_begseg x
    when 'EndSeg'
      convertz_item_endseg x
    end
  end

  def convertz_item_segment(x)
    v = @convertz_node_values[x.node_value_id]
    @bad = true if v.begr.nil? or v.endr.nil?
    @njs['messages'][-2][:value] = { docid: v.docid, beg: v.begr.to_f, type: 'real' }
    @njs['messages'][-1][:value] = { docid: v.docid, beg: v.endr.to_f, type: 'real' }
    iid = @convertz_iid
    v = { beg: iid-8, end: iid-6 }
    @njs['messages'][-3][:value] = v
    @convertz_iidmap[(x.iid-1).to_s] = v
  end

  def convertz_item_transcription(x)
    v = @convertz_node_values[x.node_value_id]
    v = { value: v.value }
    @njs['messages'] << { node: @convertz_iid-2, message: 'change', value: v }
  end

  def convertz_item_speaker(x)
    v = @convertz_node_values[x.node_value_id]
    v = { value: v.value }
    @njs['messages'] << { node: @convertz_iid-1, message: 'change', value: v }
  end

  def convertz_item_section(x)
    # @njs['messages'] << { node: @convertz_iid-2, message: 'change' }
    convertz_item_speaker x
  end

  def convertz_item_begseg(x)
    v = @convertz_node_values[x.node_value_id]
    if v and @convertz_iidmap[v.value]
      @convertz_section[:beg] = @convertz_iidmap[v.value][:beg]
    else
      @bad = true
    end
  end

  def convertz_item_endseg(x)
    v = @convertz_node_values[x.node_value_id]
    if v and @convertz_iidmap[v.value]
      @convertz_section[:end] = @convertz_iidmap[v.value][:end]
    else
      @bad = true
    end
    @njs['messages'][-2][:value] = @convertz_section
  end

  def convertz_item_create
    return if @bad
    XnnotationJournal.create(
      user_id: user_id,
      task_id: task_id,
      kit_id: id,
      tree_id: tree_id,
      json: @njs
    )
  end

end

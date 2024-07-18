class AnnotationsController < ApplicationController

  skip_before_action :verify_authenticity_token, only: :create

  include NodesHelper
  include WorkflowsHelper

  before_action :authenticate
  before_action :admin_user, :only => [:admin_annotate]

  # message protocol:  space separated messages, comma separated fields within messages
  # e.g: "4,add 5,change,blah 6,text,blah,123,456" is a sequence of 3 messages
  # message 1:  add child to node 4
  # message 2:  change value of node 5 to "blah"
  # message 3:  change text pointer of node 6 to docid=blah, beg=123, end=456
  def create
    task_user = TaskUser.find params[:task_user_id]
    @task_user = task_user
    @work_path = "/workflows/#{task_user.id}/work/#{task_user.task_workflow_id}"
    locked = false
    # this wasn't possible when the qc mode existed, but now seems like the right thing
    @response = if @current_user.id != task_user.user_id
      [ { :redirect => root_path } ]
    elsif task_user.task.status == 'inactive'
      [ { :redirect => root_path, :message => 'inactive' } ]
    elsif task_user.state == 'hold'
      [ { :redirect => root_path } ]
    else
      #set the current_task_user_id if its different than the one being annotated on, set the state to paused for the previous taskuser
      logger.debug "kit_oid #{task_user.kit_oid}"
      @current_user.update_current_task_user task_user
      logger.debug "kit_oid #{task_user.kit_oid}"
      @kit = Kit.find_by_uid(params[:qc] ? params[:kit_id] : task_user.kit_oid)
      @tree = @kit.tree
      @xlass_def = @kit.class_def.class == XlassDef
      @response = if @current_user.id != @kit.user_id #or @current_user.id != @tree.user_id
        [ { :redirect => root_path } ]
      else
        locked = true
        3.times do
          locked = Tree.where(id: @tree.id, locked: nil).update_all(locked: @current_user.id) == 0
          break unless locked
          sleep 1
        end
        if locked
          [ { error: "This tree is locked.", current: true } ]
        else
          r = helper5
          Tree.where(id: @tree.id).update_all(locked: nil)
          r
        end
      end
  
    end

    respond_to do |format|
      format.json do
        # open('/Users/jdwright/Downloads/tempout','a') do |f|
        #   f.puts request.to_json
        #   f.puts @response.to_yaml
        #   f.puts
        # end
        render :json => @response
      end
    end

  end

  def helper5
    # object being sent back via ajax (an array of responses, one for each message)
    # a workflow message will cause a redirect, essentially eliminating the responses of further messages
    request = JSON.parse params[:json]
    if request['kit_uid'] != @kit.uid
      [ { :redirect => root_path } ]
    else
      helper4 request
    end
  end

  def helper4(request)
    # protect_annotations request if task_user.task_id.in? protected_task_ids
    # work_path = "/workflows/#{task_user.task_workflow_id}/work/#{task_user.id}"
    # work_path = "/task_users/#{task_user.id}"
    helper1 request

    ut = user_helper
    # j = AnnotationJournal.create(user_id: ut[0], task_id: ut[1], kit_id: @kit.id, tree_id: @tree.id, json: params[:json], grammar: @tree.class_def.inverted_grammar.to_yaml)
    if @xlass_def
      j = XnnotationJournal.create(user_id: ut[0], task_id: ut[1], kit_id: @kit.id, tree_id: @tree.id, json: request)
      annotations = Xnnotation.includes(:node_value).where(transaction_id: j.id).order(:id).to_a
    else
      j = AnnotationJournal.create(user_id: ut[0], task_id: ut[1], kit_id: @kit.id, tree_id: @tree.id, json: params[:json], grammar: nil)
      annotations = Annotation.where(transaction_id: j.id).order(:id).to_a
    end
    time_now = Time.now
    client_time = request['client_time']

    if @xlass_def
      @nv_cache_add = {}
      @node_cache = {}
      tids = []
      annotations.each do |x|
        tids << x.iid
        if x.message == 'add'
          @nv_cache_add[x.node_value_id] = x.node_value.value.split(',').map { |x| x.split(':').first.to_i }
          tids << @nv_cache_add[x.node_value_id]
        end
      end
      Xode.includes(:node_value).where(tree_id: @tree.id, iid: tids.flatten).each do |x|
        @node_cache[x.iid] = x
      end
    end

    @response = []
    annotations.each_with_index do |a, idx|
      helper2 a, idx
    end
    @response
  end

  def helper2(a, idx)
            # node = @root.find_node a.iid
            if @xlass_def
              node = @node_cache[a.iid]
            else
              node = Node.where(tree_id: @tree.id, iid: a.iid).first
              if node.nil?
                puts "node nil for tree #{@tree.id}, iid #{a.iid}"
              end
              node_id = node.iid
            end
            message = a.message
            value = a.node_value.value
            response = { :old_id => a.iid, :message => message }
            @response << response
            #raise message.to_s
            case message
            #code to create a new mention for the coref, adding it to a specific coref entity
            when 'fork'
              response[:tree_uid] = @tree.fork.uid
            #code to update the order of the coref entities within a coref group
            when 'update_order'
              @tree.update_order node, value
            #code to mark an audio widget as finished
            #code to delete a ListItem from a List
            when 'delete'
              if @xlass_def
                response[:parent_id] = 0
              else
                response[:parent_id] = node.parent.iid
              end
              response[:annotation_id] = a.id
              # @tree.delete_node node
            #code to move a ListItem
            when 'move'
              response[:list_id] = node.iid
              response[:listitem_id] = value['iid']
              response[:old_position] = value['old_position']
              response[:new_position] = value['new_position']
              response[:target_iid] = node.children[value['new_position']].iid
              @tree.move_node node, user_id, task_id, value
              # some additional check?
            #code to add a new ListItem to a List
            when 'add'
              # new_node = @tree.add_new_node node, user_id, task_id
              # @tree.elaborate_node new_node
              #raise new_node.children.to_s
              if @xlass_def
                response[:nodes] = @nv_cache_add[a.node_value_id].map { |x| @node_cache[x].to_client_hash }
              else
                child = Node.where(tree_id: @tree.id, parent_id: node.id).last
                response[:nodes] = [ child ] + Node.where(tree_id: @tree.id, parent_id: child.id).map(&:to_client_hash)
              end
              response[:annotation_id] = a.id
              return
              node = Node.where(tree_id: @tree.id, parent_id: node.id).first
              response[:new_node] = node.initialize_from_sql(nil, @tree, @tree.class_def.inverted_grammar).to_client_hash
              @kit.read_only = false
              # response[:html] = render_to_string :partial => 'annotate/node', :locals => { :p => new_node }
            when 'noop'
              response[:noop] = true
            #code to change an existing widget's value, making an annotation
            when 'change'
              response[:parent_id] = @xlass_def ? node.parent_iid : node.parent.iid
              #return the value of the node too, necessary for Text widgets and Menu widgets at least
              response[:node] = node.to_client_hash
              response[:node]['value'][:type] = 'real' if response[:node]['value'][:beg].class == Float
              response[:annotation_id] = a.id
            else
              helper3 message, value, response
            end
  end
  def helper3(message, value, response)
              w = @task_user.task_workflow
              begin
                symbol = w.work_ajax @task_user, @kit, message, value
                case symbol
                when :work
                  response[:redirect] = @work_path
                when :home
                  response[:redirect] = root_path
                when :logout
                  response[:redirect] = logout2_path
                when :noop
                  response[:noop] = 'noop'
                else
                  raise "ajax error on message: #{message}, return value: #{symbol}"
                end
              rescue Workflow::UnknownMessageError => e
                response[:error] = "unknown message: #{message}"
              rescue Workflow::EndOfListError => e
                response[:error] = e.to_s
              rescue Workflow::NoKitError => e
                response[:redirect] = @work_path
              # rescue Lock::LockError => e
              #   response[:redirect] = root_path
              end
  end

  def helper1(request)
          if request['messages'].size == 0
            respond_to do |format|
              format.json do
                render :json => [ { :error => "empty message, nothing to do" } ]
              end
            end
            return
          end

          if request['messages'][0] =~ /^new,/
            respond_to do |format|
              format.json do
                render :json => [ { :error => "bad request, begins with 'new'" } ]
              end
            end
            return
          end
  end

  def admin_annotate
    @title = "Admin Annotation"
  end

  def find_entity(group, eid)
    if group['undone']['id'] == eid
      group['undone']
    else
      group['entities'][eid]
    end
  end

  def find_mention(group, mid)
    group.entities.each do |eid, e|
      return e.mentions[mid] if e.mentions[mid]
    end
    nil
  end

  def preann
    respond_to do |format|
      format.html { redirect_to root_path }
      format.json do
        kit = Kit.find(params[:kit_id])
        o = { done: kit.uid }
        # if kit.task_id.in? [ 12 ] # dev
        if kit.task_id.in? [ 45, 46 ]
          o[:wait] = true
          # c = KitValue.where(kit_id: kit.id, key: 'pre_ann').count
          if kit.sum.nil?
            PreAnnJob.perform_later kit, kit.task_id.in?([45])
            o[:first] = true
          end
          # KitValue.where(kit_id: kit.id, key: 'pre_ann').destroy_all
          if params[:check] and kit.sum
             o[:wait] = false
             o[:c] = kit.sum #KitValue.where(kit_id: kit.id, key: 'pre_ann').first.value
          end
        end
        render json: o
      end
    end
  end

  private

  def protect_annotations(request)
    request['messages'].each do |m|
      if m['message'] == 'change'
        if m['value'] and m['value']['value']
          case m['value']['value']
          when String
            m['value']['value'] = protect m['value']['value'] unless m['value']['value'] == ''
          when Array
            m['value']['value'].map! { |x| protect x }
          else
            raise "protected annotation error"
          end
        end
        if m['value'] and m['value']['text']
          case m['value']['text']
          when String
            m['value']['text'] = protect m['value']['text'] unless m['value']['text'] == ''
          else
            raise "protected annotation error"
          end
        end
      end
    end
  end

  def protect(x)
    c = OpenSSL::Cipher::AES128.new(:CBC)
    c.encrypt
    ckey, civ = LDCI::CONFIG[:cipher]
    c.key = ckey
    c.iv = civ
    c.update(x) + c.final
  end

end

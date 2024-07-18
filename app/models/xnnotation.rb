class Xnnotation < ApplicationRecord
  belongs_to :node_value, class_name: 'XodeValue'
  belongs_to :tree

  def node
    Xode.where(tree_id: tree_id, iid: iid).first
  end

  def apply(children=nil)
    case message
    # when 'new', 'add', 'correct'
    when 'add'
      # parent_id = Node.where( tree_id: tree_id, iid: iid ).pluck(:id).first
      parent_id = nil
      parent_iid = nil
      children = node_value.value.split(',') unless children
      # puts "children: #{children}, #{node_value_id}"
      # niid = last_iid - children.length
      children.each_with_index do |x, i|
        # niid += 1
        niid, name = x.split ':'
        # if message == 'correct'
        #   next if i == 0
        # end
        # node_class_id, level = x.split(':').map(&:to_i)
        # index =
        #   if i == 0
        #     # if message == 'new'
        #     #   Node.where(node_class_id: node_class_id).count
        #     # else
        #     #   Node.where(parent_id: parent_id).count
        #     # end
        #     # Xode.where(tree_id: tree_id, name: x).count
        #     nil
        #   else
        #     i - 1 
        #   end
        # if message == 'correct'
        #   index = i
        # end
        nd = Xode.create(
          name: name,
          parent_id: parent_id,
          parent_iid: parent_iid,
          index: (i == 0 ? nil : i - 1),
          iid: niid.to_i,
          user_id: user_id,
          task_id: task_id,
          level: (i == 0 ? 2 : 3),
          tree_id: tree_id,
          # node_class_id: node_class_id,
          node_value_id: 0
        )
        Tree.find(tree_id).update(last_iid: last_iid.to_s)
        if i == 0
          parent_id = nd.id
          parent_iid = nd.iid
        end
      end
    when 'change'
      Xode.where( tree_id: tree_id, iid: iid ).first.update( node_value_id: node_value_id, user_id: user_id, task_id: task_id )
    when 'delete'
      Xode.where( tree_id: tree_id, iid: iid ).first.destroy
      Xode.where( tree_id: tree_id, parent_iid: iid ).destroy_all
    end
  end

end

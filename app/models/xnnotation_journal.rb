=begin

annotations define a well ordered sequence of CRUD operations
new
add
change
delete

journals provide a wrapper with some implementation details, but are not
strictly necessary once that annotations exist

annotation journals follow the model of database journals or transaction logs
journals are saved with little to no logic in order to quickly persist data
in the interest of failure recovery.  journals are converted into annotations,
with the processed flag indicating completion.  once the annotations are
created, the journals serve no purpose and can be moved offline or permanently
deleted.  they can also be used to reproduce the annotations.

one journal represents one transaction, and is implemented as a database
transaction.  however, a race condition exists between journals.  for example,
a single client could send two near simultaneous messages.  an implementation
could attempt to resolve the order, e.g. with a counter, but there are complications
to this which threaten the role of journals being simple and fast.  in short,
this implementation doesn't guarantee correct ordering between journals, the order
the journals are saved defines the correct order.  however, in the case of a client
sending two messages, the client can perform sanity checks and perform it's own
recovery if the order is in fact incorrect.  Multiple annotations can be created
within a single journal, but since these are true database transactions,
everything else is well defined.  the order the journals are saved (committed)
becomes the defining order.  the primary key and timestamps reflect this order.

aside from the primary key and timestamps, a journal is a json message plus
these 4 metadata attributes

user_id
task_id
kit_id
tree_id

therefore, all the journal attributes are provided by the client request and/or
involve a minimum of logic before the journal can actually be saved.

Creating a journal results in the creation of one or more annotations as well as
the subsequent "application" of those annotations, meaning further database operations.
the annotations are an immutable sequence of recordings noting the CRUD operations and
associated data.  the annotations are ordered within the transaction based on the
client message, and across transactions by determing the most recent prior annotation

=end


require 'ostruct'
class XnnotationJournal < ApplicationRecord

  # after_create :create_annotations

  def create_annotations
    # anns = nilf
    transaction do
      last_ann = Xnnotation.where(tree_id: tree_id).last
      # last_ann = Ann.where(tree_id: kit_id).last if last_ann.nil?
      # last_ann = OpenStruct.new(id: nil, last_iid: -1) if last_ann.nil? # or tree_id.nil?
      # last_children = nil
      hash = json
      hash['messages'].each do |m|
        iid = m['node']
        message = m['message']
        value = m['value']
        case message
        when 'new'
          parent_id = nil
          last_children = nil
          last_iid = 0
        when 'add'
          parent_id = last_ann.id
          last_children = value.split ','
          last_iid = last_ann.last_iid + last_children.length
          value = { 'value' => value }
        else
          parent_id = last_ann.id
          last_children = nil
          last_iid = last_ann.last_iid
        end
        last_ann = Xnnotation.create(
          transaction_id: id,
          parent_id: parent_id,
          user_id: user_id,
          task_id: task_id,
          kit_id: kit_id,
          tree_id: tree_id,
          message: message,
          iid: iid,
          last_iid: last_iid,
          node_value: XodeValue.new_value(value)
        )
      #  anns = generate_annotations(last_ann.last_iid).map do |ann|
        # ann.parent_id = last_ann.id
        # ann.tree_id = kit_id if tree_id.nil?
        # case ann.message
        # when 'new', 'add'
        #   ann.last_iid += last_ann.last_iid
        # when 'change', 'delete'
        #   if ann.iid.nil?
        #     ann.iid = last_ann.last_iid + ann.last_iid
        #   end
        #   ann.last_iid = last_ann.last_iid
        # when 'correct'
        #   ann.last_iid = last_ann.last_iid + 2
        # else
        #   ann.last_iid = last_ann.last_iid
        # end
        # ann.save!
        # last_ann = ann
        last_ann.apply last_children
      end
      # update(processed: true)
    end
  end

end

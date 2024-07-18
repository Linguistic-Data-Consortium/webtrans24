class CreateXnnotations < ActiveRecord::Migration[7.0]
  def change
    create_table :xnnotations do |t|
      t.integer :transaction_id
      t.integer :parent_id
      t.integer :user_id
      t.integer :task_id
      t.integer :kit_id
      t.integer :tree_id
      t.integer :node_value_id
      t.integer :iid
      t.integer :last_iid
      t.string :message

      t.timestamps
    end
    add_index :xnnotations, :kit_id
    add_index :xnnotations, :node_value_id
    add_index :xnnotations, :parent_id
    add_index :xnnotations, :task_id
    add_index :xnnotations, :transaction_id
    add_index :xnnotations, :tree_id
    add_index :xnnotations, :user_id
  end
end

class CreateXodes < ActiveRecord::Migration[7.0]
  def change
    create_table :xodes do |t|
      t.string :name
      t.integer :user_id
      t.integer :task_id
      t.integer :parent_id
      t.integer :parent_iid
      t.integer :tree_id
      t.integer :node_value_id
      t.integer :index
      t.integer :iid
      t.integer :level

      t.timestamps
    end
    add_index :xodes, :tree_id
    add_index :xodes, :iid
    add_index :xodes, :parent_id
    add_index :xodes, :parent_iid
    add_index :xodes, :node_value_id
  end
end

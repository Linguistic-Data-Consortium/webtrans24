class CreateNodeLists < ActiveRecord::Migration[7.0]
  def change
    create_table :node_lists do |t|
      t.integer :class_def_id
      t.string :name
      t.text :children

      t.timestamps
    end
  end
end

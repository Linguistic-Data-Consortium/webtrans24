class CreateAction < ActiveRecord::Migration[7.0]
  def change
    create_table :actions do |t|
      t.integer :user_id
      t.integer :task_id
      t.integer :kit_id
      t.string :name
      t.bigint :client_time
      t.datetime :created_at, precision: 6, null: false
      t.index ["kit_id"], name: "index_actions_on_kit_id"
      t.index ["task_id"], name: "index_actions_on_task_id"
      t.index ["user_id"], name: "index_actions_on_user_id"
    end
  end
end

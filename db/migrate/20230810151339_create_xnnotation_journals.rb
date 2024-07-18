class CreateXnnotationJournals < ActiveRecord::Migration[7.0]
  def change
    create_table :xnnotation_journals do |t|
      t.json :json
      t.integer :user_id
      t.integer :task_id
      t.integer :kit_id
      t.integer :tree_id
      t.boolean :processed

      t.timestamps
    end
  end
end

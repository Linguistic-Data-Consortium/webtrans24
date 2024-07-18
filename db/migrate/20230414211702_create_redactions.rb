class CreateRedactions < ActiveRecord::Migration[7.0]
  def change
    create_table :redactions do |t|
      t.string :docid
      t.integer :kit_id

      t.timestamps
    end
  end
end

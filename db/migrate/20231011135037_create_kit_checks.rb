class CreateKitChecks < ActiveRecord::Migration[7.0]
  def change
    create_table :kit_checks do |t|
      t.integer :kit_id
      t.string :check

      t.timestamps
    end
    add_index :kit_checks, :kit_id
    add_index :kit_checks, :check
  end
end

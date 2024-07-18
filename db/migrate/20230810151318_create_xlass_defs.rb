class CreateXlassDefs < ActiveRecord::Migration[7.0]
  def change
    create_table :xlass_defs do |t|
      t.string :name
      t.integer :original_id
      t.json :def

      t.timestamps
    end
  end
end

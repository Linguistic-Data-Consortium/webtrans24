class CreateXodeValues < ActiveRecord::Migration[7.0]
  def change
    create_table :xode_values do |t|
      t.string :docid
      t.integer :begi
      t.integer :endi
      t.text :value
      t.text :text
      t.decimal :begr
      t.decimal :endr
      t.integer :source_id

      t.timestamps
    end
  end
end

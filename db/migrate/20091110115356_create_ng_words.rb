class CreateNgWords < ActiveRecord::Migration
  def self.up
    create_table :ng_words do |t|
      t.references :brand
      t.string :ng_word
      t.integer :ng_type

      t.timestamps
    end
  end

  def self.down
    drop_table :ng_words
  end
end

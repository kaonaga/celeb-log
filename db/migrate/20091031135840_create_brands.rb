class CreateBrands < ActiveRecord::Migration
  def self.up
    create_table :brands do |t|
      t.string :name
      t.string :phonetic
      t.integer :category, :limit => 1
      t.integer :listed_count
      t.integer :delete_flg, :limit => 1

      t.timestamps
    end
  end

  def self.down
    drop_table :brands
  end
end

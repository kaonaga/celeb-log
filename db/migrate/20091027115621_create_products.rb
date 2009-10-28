class CreateProducts < ActiveRecord::Migration
  def self.up
    create_table :products do |t|
      t.string :name
      t.string :uri
      t.string :image_string

      t.timestamps
    end
  end

  def self.down
    drop_table :products
  end
end

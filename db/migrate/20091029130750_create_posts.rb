class CreatePosts < ActiveRecord::Migration
  def self.up
    create_table :posts do |t|
      t.references :blog
      t.references :blog_entry
      t.references :brand
      t.references :product
      t.integer :delete_flg, :limit => 1
      t.timestamp :posted_date

      t.timestamps
    end
  end

  def self.down
    drop_table :posts
  end
end

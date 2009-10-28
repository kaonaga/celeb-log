class CreateBlogs < ActiveRecord::Migration
  def self.up
    create_table :blogs do |t|
      t.string :author
      t.string :phonetic
      t.string :title
      t.string :uri
      t.string :tags
      t.integer :crowl_type, :limit => 2
      t.string :last_update

      t.timestamps
    end
  end

  def self.down
    drop_table :blogs
  end
end

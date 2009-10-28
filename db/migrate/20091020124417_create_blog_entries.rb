class CreateBlogEntries < ActiveRecord::Migration
  def self.up
    create_table :blog_entries do |t|
      t.references :blog
      t.string :title
      t.text :content
      t.string :uri
      t.string :update_date

      t.timestamps
    end
  end

  def self.down
    drop_table :blog_entries
  end
end

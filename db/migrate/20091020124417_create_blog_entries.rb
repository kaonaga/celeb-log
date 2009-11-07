class CreateBlogEntries < ActiveRecord::Migration
  def self.up
    create_table :blog_entries, :options => "ENGINE=MyISAM" do |t|
    # create_table :blog_entries do |t|
      t.references :blog
      t.string :title
      t.text :content, :null => false
      t.string :uri

      t.timestamps
    end
    execute "CREATE FULLTEXT INDEX fulltext_content ON blog_entries (content)"
  end

  def self.down
    drop_table :blog_entries
  end
end

class Blog < ActiveRecord::Base
  has_many :blog_entries
  has_many :posts
end

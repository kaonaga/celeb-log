class Blog < ActiveRecord::Base
  has_many :blog_entries
  has_many :posts
  has_many :ng_words

  cattr_reader :per_page
  @@per_page = 50
end

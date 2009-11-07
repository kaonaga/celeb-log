class Post < ActiveRecord::Base
  belongs_to :blog
  belongs_to :blog_entry
  belongs_to :brand
  belongs_to :product

  cattr_reader :per_page
  @@per_page = 10

end

class BlogEntry < ActiveRecord::Base
  belongs_to :blog
  has_many :posts
end

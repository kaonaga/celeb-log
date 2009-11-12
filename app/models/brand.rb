class Brand < ActiveRecord::Base
  has_many :posts
  has_many :ng_words
end

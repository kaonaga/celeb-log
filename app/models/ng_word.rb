class NgWord < ActiveRecord::Base
  belongs_to :brand
  belongs_to :blog
  attr_accessor :name, :phonetic
end

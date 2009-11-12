class NgWord < ActiveRecord::Base
  belongs_to :brand
  attr_accessor :name, :phonetic
end

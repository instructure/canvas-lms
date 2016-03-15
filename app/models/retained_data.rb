class RetainedData < ActiveRecord::Base
  belongs_to :user
  attr_accessible :name, :value
end

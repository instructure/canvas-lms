class Favorite < ActiveRecord::Base
  belongs_to :context, :polymorphic => true
  scope :by, lambda { |type| where(:context_type => type) }
  attr_accessible :context, :context_id, :context_type
end

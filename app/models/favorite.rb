class Favorite < ActiveRecord::Base
  belongs_to :context, :polymorphic => true
  named_scope :by, lambda { |type| {:conditions => {:context_type => type}} }
  attr_accessible :context, :context_id, :context_type
end

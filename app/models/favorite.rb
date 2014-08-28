class Favorite < ActiveRecord::Base
  belongs_to :context, :polymorphic => true
  validates_inclusion_of :context_type, :allow_nil => true, :in => ['Course']
  scope :by, lambda { |type| where(:context_type => type) }
  attr_accessible :context, :context_id, :context_type

  EXPORTABLE_ATTRIBUTES = [:id, :user_id, :context_id, :context_type, :created_at, :updated_at]
  EXPORTABLE_ASSOCIATIONS = [:context]
end

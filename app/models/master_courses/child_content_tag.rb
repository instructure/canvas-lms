class MasterCourses::ChildContentTag < ActiveRecord::Base
  # can never have too many content tags

  belongs_to :child_subscription, :class_name => "MasterCourses::ChildSubscription"

  belongs_to :content, :polymorphic => true
  validates_with MasterCourses::TagValidator

  strong_params

  serialize :downstream_changes, Array # an array of changed columns
end

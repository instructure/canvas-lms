class MasterCourses::ChildContentTag < ActiveRecord::Base
  # can never have too many content tags

  belongs_to :child_subscription, :class_name => "MasterCourses::ChildSubscription"

  belongs_to :content, :polymorphic => true
  validates_with MasterCourses::TagValidator

  serialize :downstream_changes, Array # an array of changed columns

  before_create :set_migration_id

  def set_migration_id
    self.migration_id ||= content.migration_id
  end
end

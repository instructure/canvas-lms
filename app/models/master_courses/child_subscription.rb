class MasterCourses::ChildSubscription < ActiveRecord::Base
  belongs_to :master_template, :class_name => "MasterCourses::MasterTemplate"
  belongs_to :child_course, :class_name => "Course"

  strong_params

  validate :require_same_root_account

  def require_same_root_account
    # at some point we may want to expand this so it can be done across trusted root accounts
    # but for now make sure they're in the same root account so we don't have to worry about cross-shard course copies yet
    if self.child_course.root_account_id != self.master_template.course.root_account_id
      self.errors.add(:child_course_id, t("Child course must belong to the same root account as master course"))
    end
  end

  include Canvas::SoftDeletable
end

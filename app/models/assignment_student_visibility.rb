class AssignmentStudentVisibility < ActiveRecord::Base
  # necessary for general_model_spec
  attr_protected :user, :assignment, :course

  include VisibilityPluckingHelper

  belongs_to :user
  belongs_to :assignment
  belongs_to :course

  # create_or_update checks for !readonly? before persisting
  def readonly?
    true
  end

  def self.visible_assignment_ids_in_course_by_user(opts)
    visible_object_ids_in_course_by_user(:assignment_id, opts)
  end

  def self.users_with_visibility_by_assignment(opts)
    users_with_visibility_by_object_id(:assignment_id, opts)
  end

  def self.visible_assignment_ids_for_user(user_id, course_ids=nil)
    opts = {user_id: user_id}
    if course_ids
      opts[:course_id] = course_ids
    end
    self.where(opts).pluck(:assignment_id)
  end

  # readonly? is not checked in destroy though
  before_destroy { |record| raise ActiveRecord::ReadOnlyRecord }
end
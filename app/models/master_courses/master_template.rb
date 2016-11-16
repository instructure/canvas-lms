class MasterCourses::MasterTemplate < ActiveRecord::Base
  # NOTE: at some point we can use this model if we decide to allow collections of objects within a course to be pushed out
  # instead of the entire course, but for now that's what we'll roll with

  belongs_to :course

  strong_params

  include Canvas::SoftDeletable

  scope :for_full_course, -> { where(:full_course => true) }

  def self.set_as_master_course(course)
    self.unique_constraint_retry do
      course.master_course_templates.active.for_full_course.first_or_create
    end
  end

  def self.full_template_for(course)
    course.master_course_templates.active.for_full_course.first
  end
end

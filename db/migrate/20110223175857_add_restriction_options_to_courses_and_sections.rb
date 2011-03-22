class AddRestrictionOptionsToCoursesAndSections < ActiveRecord::Migration
  def self.up
    add_column :courses, :restrict_enrollments_to_course_dates, :boolean
    add_column :course_sections, :restrict_enrollments_to_section_dates, :boolean
    add_column :enrollment_terms, :ignore_term_date_restrictions, :boolean
  end

  def self.down
    remove_column :courses, :restrict_enrollments_to_course_dates
    remove_column :course_sections, :restrict_enrollments_to_section_dates
    remove_column :enrollment_terms, :ignore_term_date_restrictions
  end
end

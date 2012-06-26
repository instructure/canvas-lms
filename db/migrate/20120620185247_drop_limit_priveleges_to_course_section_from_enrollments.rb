class DropLimitPrivelegesToCourseSectionFromEnrollments < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    remove_column :enrollments, :limit_priveleges_to_course_section
  end

  def self.down
    add_column :enrollments, :limit_priveleges_to_course_section, :boolean
  end
end

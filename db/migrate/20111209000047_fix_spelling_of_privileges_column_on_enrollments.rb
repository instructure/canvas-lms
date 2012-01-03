class FixSpellingOfPrivilegesColumnOnEnrollments < ActiveRecord::Migration
  def self.up
    add_column :enrollments, :limit_privileges_to_course_section, :boolean
  end

  def self.down
    remove_column :enrollments, :limit_privileges_to_course_section
  end
end


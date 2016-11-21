class DropSectionOrganizationNameAndLongSectionCodeFromCourseSections < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    remove_column :course_sections, :section_organization_name
    remove_column :course_sections, :long_section_code
  end

  def self.down
    add_column :course_sections, :long_section_code, :string
    add_column :course_sections, :section_organization_name, :string
  end
end

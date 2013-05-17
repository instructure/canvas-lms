class IndexCourseSectionsNonxlistCourse < ActiveRecord::Migration
  tag :predeploy
  self.transactional = false

  def self.up
    add_index :course_sections, [:nonxlist_course_id], :name => "index_course_sections_on_nonxlist_course", :concurrently => true, :conditions => "nonxlist_course_id IS NOT NULL"
  end

  def self.down
    remove_index :course_sections, "index_course_sections_on_nonxlist_course"
  end
end

class IndexCourseSectionsNonxlistCourse < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def self.up
    add_index :course_sections, [:nonxlist_course_id], :name => "index_course_sections_on_nonxlist_course", :algorithm => :concurrently, :where => "nonxlist_course_id IS NOT NULL"
  end

  def self.down
    remove_index :course_sections, "index_course_sections_on_nonxlist_course"
  end
end

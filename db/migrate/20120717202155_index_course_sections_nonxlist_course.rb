class IndexCourseSectionsNonxlistCourse < ActiveRecord::Migration
  tag :predeploy
  self.transactional = false

  def self.up
    if connection.adapter_name == 'PostgreSQL'
      execute("CREATE INDEX CONCURRENTLY index_course_sections_on_nonxlist_course ON course_sections (nonxlist_course_id) WHERE nonxlist_course_id IS NOT NULL")
    else
      add_index :course_sections, [:nonxlist_course_id], :name => "index_course_sections_on_nonxlist_course"
    end
  end

  def self.down
    remove_index :course_sections, "index_course_sections_on_nonxlist_course"
  end
end

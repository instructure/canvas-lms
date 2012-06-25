class AddCoursesSisSourceIdIndex < ActiveRecord::Migration
  tag :predeploy
  self.transactional = false

  def self.up
    add_index :courses, :sis_source_id, :concurrently => true
  end

  def self.down
    remove_index :courses, :sis_source_id
  end
end

class AddCoursesSisSourceIdIndex < ActiveRecord::Migration
  tag :predeploy
  disable_ddl_transaction!

  def self.up
    add_index :courses, :sis_source_id, :concurrently => true
  end

  def self.down
    remove_index :courses, :sis_source_id
  end
end

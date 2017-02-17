class AddCoursesSisSourceIdIndex < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def self.up
    add_index :courses, :sis_source_id, :algorithm => :concurrently
  end

  def self.down
    remove_index :courses, :sis_source_id
  end
end

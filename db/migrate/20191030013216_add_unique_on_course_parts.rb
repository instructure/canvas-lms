class AddUniqueOnCourseParts < ActiveRecord::Migration
  tag :predeploy
  def up
  	add_index :course_parts, [:course_id, :title], :unique => true
  end

  def down
  	remove_index :course_parts, column: [:course_id, :title] 
  end
end

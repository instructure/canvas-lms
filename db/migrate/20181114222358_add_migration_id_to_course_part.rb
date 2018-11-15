class AddMigrationIdToCoursePart < ActiveRecord::Migration
  tag :predeploy
  def change
    add_column :course_parts, :migration_id, :string
  end
end

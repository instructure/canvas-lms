class AddColumnToMasterMigrations < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :master_courses_master_migrations, :imports_completed_at, :datetime
  end
end

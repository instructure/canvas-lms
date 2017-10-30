class DropImportResultsFromMasterMigrations < ActiveRecord::Migration[5.0]
  tag :postdeploy

  def change
    remove_column :master_courses_master_migrations, :import_results
  end
end

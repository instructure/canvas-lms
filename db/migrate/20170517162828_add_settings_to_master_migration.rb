class AddSettingsToMasterMigration < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :master_courses_master_migrations, :migration_settings, :text
  end
end

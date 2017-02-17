class UnlimitMigrationSettings < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    change_column :content_migrations, :migration_settings, :text
  end

  def down
    change_column :content_migrations, :migration_settings, :text, :limit => 500.kilobytes
  end
end

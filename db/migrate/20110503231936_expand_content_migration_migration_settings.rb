class ExpandContentMigrationMigrationSettings < ActiveRecord::Migration
  tag :predeploy

  def self.up
    change_column :content_migrations, :migration_settings, :text, :limit => 500.kilobytes
  end

  def self.down
    change_column :content_migrations, :migration_settings, :text
  end
end

class PreMigrateIgnores < ActiveRecord::Migration
  tag :predeploy
  disable_ddl_transaction!

  def self.up
    DataFixup::MigrateIgnores.run
  end
end

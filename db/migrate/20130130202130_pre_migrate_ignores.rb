class PreMigrateIgnores < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def self.up
    DataFixup::MigrateIgnores.run
  end
end

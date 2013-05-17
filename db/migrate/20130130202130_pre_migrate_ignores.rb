class PreMigrateIgnores < ActiveRecord::Migration
  tag :predeploy
  self.transactional = false

  def self.up
    DataFixup::MigrateIgnores.run
  end
end

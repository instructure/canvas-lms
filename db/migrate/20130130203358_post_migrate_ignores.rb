class PostMigrateIgnores < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    DataFixup::MigrateIgnores.send_later_if_production(:run)
  end
end

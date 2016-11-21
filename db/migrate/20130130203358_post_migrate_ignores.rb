class PostMigrateIgnores < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction! unless Rails.env.production?

  def self.up
    DataFixup::MigrateIgnores.send_later_if_production(:run)
  end
end

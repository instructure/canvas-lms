class PostMigrateIgnores < ActiveRecord::Migration
  tag :postdeploy
  self.transactional = Rails.env.production?

  def self.up
    DataFixup::MigrateIgnores.send_later_if_production(:run)
  end
end

class UseNewSisAppUrlAccountSetting < ActiveRecord::Migration
  tag :postdeploy
  disable_ddl_transaction! unless Rails.env.production?

  def self.up
    DataFixup::SisAppUrlAccountSetting.send_later_if_production(:run)
  end
end

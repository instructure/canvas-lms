class AddIndexOnCccc < ActiveRecord::Migration
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    add_index :communication_channels, :confirmation_code, concurrently: true
  end

  def self.down
    remove_index :communication_channels, :confirmation_code
  end
end

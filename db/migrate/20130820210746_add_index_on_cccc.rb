class AddIndexOnCccc < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    add_index :communication_channels, :confirmation_code, algorithm: :concurrently
  end

  def self.down
    remove_index :communication_channels, :confirmation_code
  end
end

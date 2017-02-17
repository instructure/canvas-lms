class AddParentMd5ToBrandConfigs < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :brand_configs, :parent_md5, :string
  end

  def self.down
    remove_column :brand_configs, :parent_md5
  end
end

class AddOverridesToBrandConfig < ActiveRecord::Migration
  tag :predeploy
  def change
    add_column :brand_configs, :js_overrides, :text
    add_column :brand_configs, :css_overrides, :text
  end
end

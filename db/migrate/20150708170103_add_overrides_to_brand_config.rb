class AddOverridesToBrandConfig < ActiveRecord::Migration[4.2]
  tag :predeploy
  def change
    add_column :brand_configs, :js_overrides, :text
    add_column :brand_configs, :css_overrides, :text
    add_column :brand_configs, :mobile_js_overrides, :text
    add_column :brand_configs, :mobile_css_overrides, :text
  end
end

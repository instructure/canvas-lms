class AddMobileOverridesToBrandConfig < ActiveRecord::Migration[4.2]
  tag :predeploy
  def up
    unless column_exists? :brand_configs, :mobile_js_overrides
      add_column :brand_configs, :mobile_js_overrides, :text
    end
    unless column_exists? :brand_configs, :mobile_css_overrides
      add_column :brand_configs, :mobile_css_overrides, :text
    end
  end
end

class DropCustomFieldTables < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    # these tables may not have ever been created
    drop_table "custom_fields" if table_exists?("custom_fields")
    drop_table "custom_field_values" if table_exists?("custom_field_values")
  end

  def self.down
  end
end

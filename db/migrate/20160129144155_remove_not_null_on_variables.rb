class RemoveNotNullOnVariables < ActiveRecord::Migration
  tag :predeploy

  def up
    change_column_null :brand_configs, :variables, true
  end

  def down
    change_column_null :brand_configs, :variables, false
  end
end

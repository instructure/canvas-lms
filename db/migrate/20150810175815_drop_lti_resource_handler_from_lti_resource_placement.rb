class DropLtiResourceHandlerFromLtiResourcePlacement < ActiveRecord::Migration
  tag :postdeploy
  def change
    remove_column :lti_resource_placements, :resource_handler_id
  end
end

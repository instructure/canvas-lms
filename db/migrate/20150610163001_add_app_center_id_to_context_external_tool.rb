class AddAppCenterIdToContextExternalTool < ActiveRecord::Migration[4.2]
  tag :predeploy
  def change
    add_column :context_external_tools, :app_center_id, :string
  end
end

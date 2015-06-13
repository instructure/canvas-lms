class AddExternalToolsNotSelectableColumn < ActiveRecord::Migration
  tag :predeploy

  def change
    add_column :context_external_tools, :not_selectable, :boolean
  end
end

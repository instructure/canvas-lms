class AddExternalToolsNotSelectableColumn < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :context_external_tools, :not_selectable, :boolean
  end
end

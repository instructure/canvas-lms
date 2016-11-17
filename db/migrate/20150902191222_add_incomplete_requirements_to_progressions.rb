class AddIncompleteRequirementsToProgressions < ActiveRecord::Migration[4.2]
  tag :predeploy
  def up
    add_column :context_module_progressions, :incomplete_requirements, :text
  end

  def down
    add_column :context_module_progressions, :incomplete_requirements
  end
end

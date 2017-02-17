class AddRequirementCountToContextModules < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :context_modules, :requirement_count, :integer
  end
end

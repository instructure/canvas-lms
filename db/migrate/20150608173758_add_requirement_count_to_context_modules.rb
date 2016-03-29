class AddRequirementCountToContextModules < ActiveRecord::Migration
  tag :predeploy

  def change
    add_column :context_modules, :requirement_count, :integer
  end
end

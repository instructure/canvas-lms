class AddDefaultValueToContextModuleProgression < ActiveRecord::Migration[5.0]
  tag :postdeploy
  def change
    change_column :context_module_progressions, :collapsed, :boolean, default: true
  end
end

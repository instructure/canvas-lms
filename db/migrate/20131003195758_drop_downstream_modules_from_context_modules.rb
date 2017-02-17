class DropDownstreamModulesFromContextModules < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    remove_column :context_modules, :downstream_modules
  end

  def self.down
    add_column :context_modules, :downstream_modules, :text
  end
end

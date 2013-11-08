class DropDownstreamModulesFromContextModules < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    remove_column :context_modules, :downstream_modules
  end

  def self.down
    add_column :context_modules, :downstream_modules, :text
  end
end

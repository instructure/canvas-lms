class PopulateLockVersionOnContextModuleProgressions < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    DataFixup::PopulateLockVersionOnContextModuleProgressions.run
  end
end

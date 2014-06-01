class PopulateLockVersionOnContextModuleProgressions < ActiveRecord::Migration
  tag :predeploy

  def self.up
    DataFixup::PopulateLockVersionOnContextModuleProgressions.run
  end
end

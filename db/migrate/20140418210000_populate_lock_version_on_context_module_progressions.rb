class PopulateLockVersionOnContextModuleProgressions < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    DataFixup::PopulateLockVersionOnContextModuleProgressions.run
  end
end

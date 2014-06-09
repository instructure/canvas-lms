class AddEvaluatedAtToContextModuleProgressions < ActiveRecord::Migration
  tag :predeploy

  def self.up
    add_column :context_module_progressions, :evaluated_at, :datetime
  end

  def self.down
    remove_column :context_module_progressions, :evaluated_at
  end
end

class AddDisplayNameToLearningOutcomes < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :learning_outcomes, :display_name, :string
  end

  def self.down
    remove_column :learning_outcomes, :display_name
  end
end

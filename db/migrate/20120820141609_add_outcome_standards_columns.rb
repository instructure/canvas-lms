class AddOutcomeStandardsColumns < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :learning_outcomes, :vendor_guid, :string
    add_column :learning_outcomes, :low_grade, :string
    add_column :learning_outcomes, :high_grade, :string
    add_index :learning_outcomes, :vendor_guid, :name => "index_learning_outcomes_on_vendor_guid"

    add_column :learning_outcome_groups, :vendor_guid, :string
    add_column :learning_outcome_groups, :low_grade, :string
    add_column :learning_outcome_groups, :high_grade, :string
    add_index :learning_outcome_groups, :vendor_guid, :name => "index_learning_outcome_groups_on_vendor_guid"
  end

  def self.down
    remove_index :learning_outcomes, :name => "index_learning_outcomes_on_vendor_guid"
    remove_column :learning_outcomes, :vendor_guid
    remove_column :learning_outcomes, :low_grade
    remove_column :learning_outcomes, :high_grade

    remove_index :learning_outcome_groups, :name => "index_learning_outcome_groups_on_vendor_guid"
    remove_column :learning_outcome_groups, :vendor_guid
    remove_column :learning_outcome_groups, :low_grade
    remove_column :learning_outcome_groups, :high_grade
  end
end

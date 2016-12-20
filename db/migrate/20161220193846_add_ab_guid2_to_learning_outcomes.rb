class AddAbGuid2ToLearningOutcomes < ActiveRecord::Migration[4.2]
  tag :predeploy

  disable_ddl_transaction!

  def change
    add_column :learning_outcomes, :vendor_guid_2, :string, limit: 255
    add_column :learning_outcomes, :migration_id_2, :string, limit: 255
    add_column :learning_outcome_groups, :vendor_guid_2, :string, limit: 255
    add_column :learning_outcome_groups, :migration_id_2, :string, limit: 255
    add_index :learning_outcomes, :vendor_guid_2, :name => "index_learning_outcomes_on_vendor_guid_2", :algorithm => :concurrently
    add_index :learning_outcome_groups, :vendor_guid_2, :name => "index_learning_outcome_groups_on_vendor_guid_2", :algorithm => :concurrently
  end
end

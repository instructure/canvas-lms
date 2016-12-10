class AddAssociatedAssetToLearningOutcomeResults < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :learning_outcome_results, :associated_asset_id, :integer, :limit => 8
    add_column :learning_outcome_results, :associated_asset_type, :string
    remove_index :learning_outcome_results, [:user_id, :content_tag_id]
    add_index :learning_outcome_results, [:user_id, :content_tag_id, :associated_asset_id, :associated_asset_type], :unique => true, :name => "index_learning_outcome_results_association"
  end

  def self.down
    # Not possible to reliably revert to the old index,
    # which was only on user_id and content_tag_id
    raise ActiveRecord::IrreversibleMigration
  end
end

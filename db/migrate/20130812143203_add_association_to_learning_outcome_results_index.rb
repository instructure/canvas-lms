class AddAssociationToLearningOutcomeResultsIndex < ActiveRecord::Migration
  self.transactional = false
  tag :postdeploy

  def self.up
    remove_index :learning_outcome_results, name: "index_learning_outcome_results_association"
    add_index :learning_outcome_results, [:user_id, :content_tag_id, :association_id, :association_type, :associated_asset_id, :associated_asset_type], unique: true, name: "index_learning_outcome_results_association", concurrently: true
  end

  def self.down
    # Not possible to reliably revert to the old index, which was only on
    # user_id and content_tag_id, and associated_asset
    raise ActiveRecord::IrreversibleMigration
  end
end

class AddAssociationToLearningOutcomeResultsIndex < ActiveRecord::Migration
  tag :postdeploy
  disable_ddl_transaction!

  def self.up
    rename_index :learning_outcome_results, 'index_learning_outcome_results_association', 'temp_index_learning_outcome'
    LearningOutcomeResult.
      select("user_id, content_tag_id, association_id, association_type,
              associated_asset_id, associated_asset_type").
      group("user_id, content_tag_id, association_id, association_type,
             associated_asset_id, associated_asset_type").
      having("COUNT(*) > 1").find_each do |lor|
      scope = LearningOutcomeResult.
        where(user_id: lor.user_id,
              content_tag_id: lor.content_tag_id,
              associated_asset_id: lor.associated_asset_id,
              association_id: lor.association_id,
              association_type: lor.association_type,
              associated_asset_type: lor.associated_asset_type)
      keeper = scope.order("updated_at DESC").first
      scope.where("id<>?", keeper).delete_all
    end
    add_index :learning_outcome_results,
              [:user_id, :content_tag_id, :association_id, :association_type, :associated_asset_id, :associated_asset_type],
              unique: true,
              name: "index_learning_outcome_results_association",
              algorithm: :concurrently
    remove_index :learning_outcome_results, name: "temp_index_learning_outcome"
  end

  def self.down
    # Not possible to reliably revert to the old index, which was only on
    # user_id and content_tag_id, and associated_asset
    raise ActiveRecord::IrreversibleMigration
  end
end

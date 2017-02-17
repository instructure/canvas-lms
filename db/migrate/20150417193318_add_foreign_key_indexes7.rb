class AddForeignKeyIndexes7 < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    add_index :quiz_question_regrades, :quiz_question_id, name: 'index_qqr_on_qq_id', algorithm: :concurrently
    add_index :learning_outcome_groups, :root_learning_outcome_group_id, where: "root_learning_outcome_group_id IS NOT NULL", algorithm: :concurrently
    add_index :learning_outcome_results, :content_tag_id, algorithm: :concurrently
  end
end

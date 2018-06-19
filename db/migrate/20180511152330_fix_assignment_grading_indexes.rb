class FixAssignmentGradingIndexes < ActiveRecord::Migration[5.1]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    remove_index :assignments, :grader_section_id if index_exists?(:assignments, :grader_section_id)
    remove_index :assignments, :final_grader_id if index_exists?(:assignments, :final_grader_id)
    add_index :assignments, :grader_section_id, where: "grader_section_id IS NOT NULL", algorithm: :concurrently
    add_index :assignments, :final_grader_id, where: "final_grader_id IS NOT NULL", algorithm: :concurrently
  end
end

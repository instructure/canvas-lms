class CascadeFkIdxsToAuditorGradeChanges < CanvasPartman::Migration
  disable_ddl_transaction!
  tag :postdeploy
  self.base_class = Auditors::ActiveRecord::GradeChangeRecord

  def up
    with_each_partition do |partition|
      add_index partition, :account_id, algorithm: :concurrently
      add_index partition, :submission_id, algorithm: :concurrently
      add_index partition, :student_id, algorithm: :concurrently
      add_index partition, :grader_id, algorithm: :concurrently
    end
  end

  def down
    with_each_partition do |partition|
      remove_index partition, :account_id, algorithm: :concurrently
      remove_index partition, :submission_id, algorithm: :concurrently
      remove_index partition, :student_id, algorithm: :concurrently
      remove_index partition, :grader_id, algorithm: :concurrently
    end
  end
end

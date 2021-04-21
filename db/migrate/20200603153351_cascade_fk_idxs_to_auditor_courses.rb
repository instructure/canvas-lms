# frozen_string_literal: true

class CascadeFkIdxsToAuditorCourses < CanvasPartman::Migration
  disable_ddl_transaction!
  tag :postdeploy
  self.base_class = Auditors::ActiveRecord::CourseRecord

  def up
    with_each_partition do |partition|
      add_index partition, :sis_batch_id, algorithm: :concurrently
      add_index partition, :user_id, algorithm: :concurrently
    end
  end

  def down
    with_each_partition do |partition|
      remove_index partition, :sis_batch_id, algorithm: :concurrently
      remove_index partition, :user_id, algorithm: :concurrently
    end
  end
end

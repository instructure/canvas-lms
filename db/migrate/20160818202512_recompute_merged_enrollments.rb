class RecomputeMergedEnrollments < ActiveRecord::Migration
  disable_ddl_transaction!
  tag :postdeploy

  def up
    start_date = DateTime.parse("2016-08-05")
    merged_enrollment_ids = UserMergeDataRecord.where(:context_type => "Enrollment").
      joins(:user_merge_data).where("user_merge_data.updated_at > ?", start_date).pluck(:context_id)

    if merged_enrollment_ids.any?
      Shard.partition_by_shard(merged_enrollment_ids) do |sliced_ids|
        EnrollmentState.invalidate_states(Enrollment.where(:id => sliced_ids))
        EnrollmentState.send_later_if_production(:process_states_for_ids, sliced_ids)
      end
    end
  end

  def down
  end
end

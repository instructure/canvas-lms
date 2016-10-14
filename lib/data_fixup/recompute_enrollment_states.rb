module DataFixup
  module RecomputeEnrollmentStates
    def self.run(start_at, end_at)
      Enrollment.find_ids_in_ranges(:start_at => start_at, :end_at => end_at) do |min_id, max_id|
        enrollments = Enrollment.where(:id => min_id..max_id).to_a

        Canvas::Builders::EnrollmentDateBuilder.preload(enrollments, false)

        enrollments.each do |enrollment|
          state = enrollment.enrollment_state
          state.skip_touch_user = true

          state.state_is_current = false
          state.access_is_current = false
          state.ensure_current_state
        end

        user_ids_to_touch = enrollments.select{|e| e.enrollment_state.user_needs_touch}.map(&:user_id)
        if user_ids_to_touch.any?
          Shard.partition_by_shard(user_ids_to_touch) do |sliced_user_ids|
            User.where(:id => sliced_user_ids).touch_all
          end
        end
      end
    end
  end
end
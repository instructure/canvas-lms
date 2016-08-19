module DataFixup
  module FixDeletedEnrollmentStates
    def self.run
      Enrollment.find_ids_in_ranges(:batch_size => 20000) do |min_id, max_id|
        # find deleted enrollments with states that haven't been properly synced
        ids = Enrollment.where(:id => min_id..max_id).
          where(:workflow_state => 'deleted').
          joins(:enrollment_state).where("enrollment_states.state <> 'deleted'").pluck(:id)

        EnrollmentState.force_recalculation(ids)
      end
    end
  end
end

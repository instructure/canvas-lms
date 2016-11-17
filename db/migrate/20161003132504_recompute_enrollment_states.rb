class RecomputeEnrollmentStates < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    # copy-pasted from build_enrollment_states
    # try to partition off ranges of ids in the table with at most 50,000 ids per partition
    ranges = []
    current_min = Enrollment.minimum(:id)
    return unless current_min

    range_size = 50_000

    while current_min
      current_max = current_min + range_size - 1

      next_min = Enrollment.where("id > ?", current_max).minimum(:id)
      if next_min
        ranges << [current_min, current_max]
      elsif !next_min && ranges.any?
        ranges << [current_min, nil]
      end
      current_min = next_min
    end

    unless ranges.any?
      ranges = [[nil, nil]]
    end

    ranges.each do |start_at, end_at|
      DataFixup::RecomputeEnrollmentStates.send_later_if_production_enqueue_args(:run,
        {:strand => "enrollment_state_recomputing_#{Shard.current.database_server.id}", :priority => Delayed::MAX_PRIORITY}, start_at, end_at)
    end
  end

  def down
  end
end

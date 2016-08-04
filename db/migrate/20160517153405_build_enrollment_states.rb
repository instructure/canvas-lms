class BuildEnrollmentStates < ActiveRecord::Migration
  tag :postdeploy

  def up
    # try to partition off ranges of ids in the table with at most 10,000 ids per partition
    ranges = []
    current_min = Enrollment.minimum(:id)
    return unless current_min

    range_size = 10_000

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
      EnrollmentState.send_later_if_production_enqueue_args(:process_states_in_ranges,
        {:strand => "enrollment_state_building_#{Shard.current.database_server.id}", :priority => Delayed::MAX_PRIORITY}, start_at, end_at)
    end
  end

  def down
  end
end

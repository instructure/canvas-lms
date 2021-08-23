# frozen_string_literal: true

class PopulateCourseIdOnSubmissions < ActiveRecord::Migration[5.2]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    Submission.find_ids_in_ranges(:batch_size => 100_000) do |start_at, end_at|
      DataFixup::PopulateCourseIdOnSubmissions.
        delay_if_production(priority: Delayed::LOWER_PRIORITY, n_strand: ["submission_course_id_population", Shard.current.database_server.id]).
        run(start_at, end_at)
    end
  end

  def down
  end
end

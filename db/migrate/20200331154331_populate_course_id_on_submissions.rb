class PopulateCourseIdOnSubmissions < ActiveRecord::Migration[5.2]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    Submission.find_ids_in_ranges(:batch_size => 100_000) do |start_at, end_at|
      DataFixup::PopulateCourseIdOnSubmissions.send_later_if_production_enqueue_args(:run,
        {:priority => Delayed::LOWER_PRIORITY, :n_strand => ["submission_course_id_population", Shard.current.database_server.id]},
        start_at, end_at
      )
    end
  end

  def down
  end
end

class PopulateLastCommentAtOnSubmissions < ActiveRecord::Migration[5.0]
  tag :postdeploy

  def up
    Submission.find_ids_in_ranges(:batch_size => 1_000_000) do |start_at, end_at|
      DataFixup::PopulateLastCommentAtOnSubmissions.send_later_if_production_enqueue_args(
        :run,
        {
          priority: Delayed::LOW_PRIORITY, max_attempts: 1,
          n_strand: ['DataFixup::PopulateLastCommentAtOnSubmissions', Shard.current.database_server.id]
        },
        start_at, end_at
      )
    end
  end

  def down
  end
end

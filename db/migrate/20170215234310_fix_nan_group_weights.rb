class FixNanGroupWeights < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    DataFixup::FixNanGroupWeights.send_later_if_production_enqueue_args(
      :run, {
        priority: Delayed::LOWER_PRIORITY,
        max_attempts: 1,
        n_strand: "data_fixups:#{Shard.current.database_server.id}"
      }
    )
  end

  def down
  end
end

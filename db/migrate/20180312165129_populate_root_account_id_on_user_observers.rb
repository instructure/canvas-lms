class PopulateRootAccountIdOnUserObservers < ActiveRecord::Migration[5.0]
  tag :postdeploy

  def up
    DataFixup::PopulateRootAccountIdOnUserObservers.send_later_if_production_enqueue_args(
      :run,
      {
        priority: Delayed::LOW_PRIORITY,
        strand: "DataFixup::PopulateRootAccountIdOnUserObservers:#{Shard.current.database_server.id}"
      }
    )
  end

  def down
  end
end

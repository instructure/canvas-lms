class SplitUpUserPreferences < ActiveRecord::Migration[5.2]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    User.find_ids_in_ranges(:batch_size => 200_000) do |min_id, max_id|
      DataFixup::SplitUpUserPreferences.send_later_if_production_enqueue_args(:run,
        {:priority => Delayed::LOW_PRIORITY, :n_strand => ["user_preference_migration", Shard.current.database_server.id]},
        min_id, max_id
      )
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end

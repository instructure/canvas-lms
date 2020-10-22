class SplitUpUserPreferences < ActiveRecord::Migration[5.2]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    User.find_ids_in_ranges(:batch_size => 20_000) do |min_id, max_id|
      DataFixup::SplitUpUserPreferences.
        delay_if_production(priority: Delayed::LOW_PRIORITY, n_strand => ["user_preference_migration", Shard.current.database_server.id]).
        run(min_id, max_id)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end

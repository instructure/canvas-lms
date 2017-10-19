class RepairCrossShardUserObservers < ActiveRecord::Migration[5.0]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    remove_foreign_key :user_observers, column: :observer_id

    UserObserver.where("user_id/?<>observer_id/?", Shard::IDS_PER_SHARD, Shard::IDS_PER_SHARD).find_each do |uo|
      # just "restore" it - will automatically create the missing side, and create enrollments that
      # may not have worked initially
      UserObserver.create_or_restore(observer: uo.observer, observee: uo.user)
    end
  end
end

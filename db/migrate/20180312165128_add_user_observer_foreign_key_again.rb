class AddUserObserverForeignKeyAgain < ActiveRecord::Migration[5.0]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    unless foreign_key_exists?(:user_observers, :column => :observer_id)
      UserObservationLink.where("observer_id > ?", Shard::IDS_PER_SHARD).find_in_batches do |uos|
        observer_ids = uos.map(&:observer_id).uniq
        missing_ids = observer_ids - User.where("id IN (?)", observer_ids).pluck(:id)
        if missing_ids.any?
          uos.select{|uo| missing_ids.include?(uo.observer_id)}.each do |uo|
            uo.observer.associate_with_shard(Shard.current, :shadow)
          end
        end
      end
      add_foreign_key :user_observers, :users, :column => :observer_id
    end
  end

  def down
    remove_foreign_key_if_exists :user_observers, :column => :observer_id
  end
end

class ReintroduceDeletedEntriesToUnreadCount < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    DataFixup::ReintroduceDeletedEntriesToUnreadCount.send_later_if_production_enqueue_args(:run, :priority => Delayed::LOW_PRIORITY)
  end

  def self.down
  end
end

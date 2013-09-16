class FilterPageViewUrlParams < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    if [:db, :cache].include?(PageView.page_view_method) ||
        (PageView.cassandra? && Shard.current.default?)
      DataFixup::FilterPageViewUrlParams.send_later_if_production_enqueue_args(:run,
        :priority => Delayed::LOW_PRIORITY, :max_attempts => 1)
    end
  end

  def self.down
  end
end

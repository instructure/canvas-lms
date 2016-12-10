class TouchDiscussionTopics < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    # mark all materialized views as out of date
    DiscussionTopic.send_later_if_production_enqueue_args(:touch_all_records, :priority => Delayed::LOW_PRIORITY)
  end

  def down
  end
end

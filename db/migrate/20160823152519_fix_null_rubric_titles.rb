class FixNullRubricTitles < ActiveRecord::Migration
  tag :postdeploy

  def up
    DataFixup::FixNullRubricTitles.send_later_if_production_enqueue_args(
      :run, :priority => Delayed::LOW_PRIORITY, :max_attempts => 1)
  end

  def down
  end
end

class DeleteEmptyProgressions < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    DataFixup::DeleteEmptyProgressions.send_later_if_production_enqueue_args(:run, :priority => Delayed::LOW_PRIORITY)
  end
end

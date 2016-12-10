class RemoveInvalidObservers < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    DataFixup::RemoveInvalidObservers.send_later_if_production_enqueue_args(
      :run,
      :priority => Delayed::LOWER_PRIORITY
    )
  end

  def down
  end
end

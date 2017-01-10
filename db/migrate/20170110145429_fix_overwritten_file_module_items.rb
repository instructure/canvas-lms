class FixOverwrittenFileModuleItems < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    DataFixup::FixOverwrittenFileModuleItems.send_later_if_production_enqueue_args(:run, :priority => Delayed::LOW_PRIORITY)
  end

  def down
  end
end

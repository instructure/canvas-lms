class DeleteFacebookChannels < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    DataFixup::DeleteFacebookChannels.send_later_if_production_enqueue_args(
      :run,
      :priority => Delayed::LOWER_PRIORITY,
      :max_attempts => 1)
  end

  def down
  end
end

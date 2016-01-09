class FixFolderNames < ActiveRecord::Migration
  tag :postdeploy
  def up
    DataFixup::FixFolderNames.send_later_if_production_enqueue_args(:run,
      :priority => Delayed::LOW_PRIORITY, :n_strand => 'long_datafixups')
  end
end

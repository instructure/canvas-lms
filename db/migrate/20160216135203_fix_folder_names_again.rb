class FixFolderNamesAgain < ActiveRecord::Migration[4.2]
  tag :postdeploy
  def up
    DataFixup::FixFolderNames.send_later_if_production_enqueue_args(:run,
      :priority => Delayed::LOW_PRIORITY, :n_strand => 'long_datafixups')
  end
end

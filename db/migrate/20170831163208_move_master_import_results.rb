class MoveMasterImportResults < ActiveRecord::Migration[5.0]
  tag :postdeploy

  def up
    DataFixup::MoveMasterImportResults.send_later_if_production_enqueue_args(
      :run, :priority => Delayed::LOW_PRIORITY, :n_strand => 'long_datafixups')
  end

  def down
  end
end

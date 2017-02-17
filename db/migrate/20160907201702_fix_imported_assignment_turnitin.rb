class FixImportedAssignmentTurnitin < ActiveRecord::Migration[4.2]
  tag :postdeploy
  def up
    DataFixup::FixImportedAssignmentTurnitin.send_later_if_production_enqueue_args(:run,
      :priority => Delayed::LOW_PRIORITY, :n_strand => 'long_datafixups')
  end

  def down
  end
end

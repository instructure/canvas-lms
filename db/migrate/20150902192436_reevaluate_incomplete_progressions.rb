class ReevaluateIncompleteProgressions < ActiveRecord::Migration
  tag :postdeploy

  def up
    # mark them all as out of date
    while ContextModuleProgression.where(:workflow_state => ['unlocked', 'started'], :current => true).
      limit(1000).update_all(:current => false) > 0; end

    DataFixup::ReevaluateIncompleteProgressions.send_later_if_production_enqueue_args(:run,
      :priority => Delayed::LOW_PRIORITY, :n_strand => 'long_datafixups')
  end

  def down
  end
end

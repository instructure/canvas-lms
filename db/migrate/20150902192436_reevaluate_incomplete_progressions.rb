class ReevaluateIncompleteProgressions < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    # mark them all as out of date
    ContextModuleProgression.find_ids_in_ranges(:batch_size => 10000) do |min_id, max_id|
      ContextModuleProgression.where(:workflow_state => ['unlocked', 'started'], :current => true,
        :id => min_id..max_id).update_all(:current => false)
    end

    DataFixup::ReevaluateIncompleteProgressions.send_later_if_production_enqueue_args(:run,
      :priority => Delayed::LOW_PRIORITY, :n_strand => 'long_datafixups')
  end

  def down
  end
end

class PopulateSubmissionVersions < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    DataFixup::PopulateSubmissionVersions.send_later_if_production_enqueue_args(:run,
      :priority => Delayed::LOWER_PRIORITY, :max_attempts => 1, :n_strand => 'long_datafixups')
  end
end

class FixOldSubmissionVersionYaml < ActiveRecord::Migration
  tag :postdeploy

  def up
    DataFixup::FixOldSubmissionVersionYAML.send_later_if_production_enqueue_args(:run, :priority => Delayed::LOW_PRIORITY)
  end

  def down
  end
end

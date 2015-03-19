class FixCorruptAssessmentQuestionsFromCnvs19292 < ActiveRecord::Migration
  tag :postdeploy

  def up
    DataFixup::FixCorruptAssessmentQuestionsFromCnvs19292.send_later_if_production_enqueue_args(:run, :priority => Delayed::LOW_PRIORITY, :max_attempts => 1)
  end
end

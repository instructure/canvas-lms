class FixCorruptAssessmentQuestionsFromCnvs19292 < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    DataFixup::FixCorruptAssessmentQuestionsFromCnvs19292.send_later_if_production_enqueue_args(
      :run,
      {
        :priority => Delayed::LOW_PRIORITY,
        :max_attempts => 1
      },
      [
        'calculated_question',
        'numerical_question',
        'matching_question',
        'multiple_dropdowns_question'
      ]
    )
  end
end

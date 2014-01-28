require 'lib/data_fixup/change_graded_survey_submissions_to_not_need_grading'
class ChangeGradedSurveySubmissionsToNotNeedGrading < ActiveRecord::Migration
  tag :postdeploy
  def self.up
    DataFixup::ChangeGradedSurveySubmissionsToNotNeedGrading.
      send_later_if_production(:run)
  end
end

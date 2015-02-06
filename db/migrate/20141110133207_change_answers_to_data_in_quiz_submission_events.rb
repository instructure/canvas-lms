class ChangeAnswersToDataInQuizSubmissionEvents < ActiveRecord::Migration
  tag :predeploy

  def change
    # no data in this table yet, no need for data fixup
    rename_column :quiz_submission_events, :answers, :event_data
  end
end

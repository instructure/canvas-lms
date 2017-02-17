class AddNonNullConstraintsToQuizSubmissionEvents < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    change_column_null :quiz_submission_events, :event_type, false
    change_column_null :quiz_submission_events, :attempt, false
    change_column_null :quiz_submission_events, :created_at, false
  end
end

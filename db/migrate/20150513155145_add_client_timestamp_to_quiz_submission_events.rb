class AddClientTimestampToQuizSubmissionEvents < ActiveRecord::Migration[4.2]
  tag :predeploy
  def change
    add_column :quiz_submission_events, :client_timestamp, :datetime
  end
end

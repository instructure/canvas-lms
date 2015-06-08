class AddClientTimestampToQuizSubmissionEvents < ActiveRecord::Migration
  tag :predeploy
  def change
    add_column :quiz_submission_events, :client_timestamp, :datetime
  end
end

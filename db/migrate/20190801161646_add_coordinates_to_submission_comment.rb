class AddCoordinatesToSubmissionComment < ActiveRecord::Migration
  tag :predeploy
  def change
    add_column :submission_comments, :attached_to, :string
    add_column :submission_comments, :x, :integer
    add_column :submission_comments, :y, :integer
  end
end

class ChangeSubmissionCommentDraftDefault < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    change_column_default(:submission_comments, :draft, false)
    DataFixup::BackfillNulls.run(SubmissionComment, :draft, default_value: false, batch_size: 10000)
  end

  def down
    change_column_default(:submission_comments, :draft, nil)
  end
end

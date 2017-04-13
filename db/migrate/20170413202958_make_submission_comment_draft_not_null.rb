class MakeSubmissionCommentDraftNotNull < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    change_column_null(:submission_comments, :draft, false)
  end

  def down
    change_column_null(:submission_comments, :draft, true)
  end
end

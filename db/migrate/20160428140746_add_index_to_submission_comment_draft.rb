class AddIndexToSubmissionCommentDraft < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    add_index :submission_comments, :draft, algorithm: :concurrently
  end
end

class AddIndexToSubmissionCommentDraft < ActiveRecord::Migration
  tag :postdeploy
  disable_ddl_transaction!

  def change
    add_index :submission_comments, :draft, algorithm: :concurrently
  end
end

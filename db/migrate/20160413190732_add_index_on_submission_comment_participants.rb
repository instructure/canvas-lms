class AddIndexOnSubmissionCommentParticipants < ActiveRecord::Migration[4.2]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    add_index :submission_comment_participants, [:user_id, :participation_type],
              algorithm: :concurrently,
              name: 'index_scp_on_user_id_and_participation_type'
  end
end

class DropSubmissionCommentParticipants < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    drop_table :submission_comment_participants
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end

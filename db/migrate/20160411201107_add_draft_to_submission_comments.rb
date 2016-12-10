class AddDraftToSubmissionComments < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    add_column :submission_comments, :draft, :boolean

    change_column_default :submission_comments, :draft, false
  end

  def down
    remove_column :submission_comments, :draft
  end
end

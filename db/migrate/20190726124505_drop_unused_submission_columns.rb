# frozen_string_literal: true

class DropUnusedSubmissionColumns < ActiveRecord::Migration[5.1]
  tag :postdeploy

  def up
    remove_column :submissions, :has_admin_comment
    remove_column :submissions, :has_rubric_assessment
    remove_column :submissions, :process_attempts
  end

  def down
    add_column :submissions, :has_admin_comment, :boolean
    add_column :submissions, :has_rubric_assessment, :boolean
    add_column :submissions, :process_attempts, :integer
  end
end

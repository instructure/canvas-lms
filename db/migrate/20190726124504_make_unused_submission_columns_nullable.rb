# frozen_string_literal: true

class MakeUnusedSubmissionColumnsNullable < ActiveRecord::Migration[5.1]
  tag :predeploy

  def change
    change_column_null(:submissions, :has_admin_comment, false)
  end
end

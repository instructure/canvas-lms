class DropBeforeQuizSubmissionTypesColumn < ActiveRecord::Migration
  tag :postdeploy

  def self.up
    remove_column :assignments, :before_quiz_submission_types
  end

  def self.down
    add_column :assignments, :string, :before_quiz_submission_types
  end
end

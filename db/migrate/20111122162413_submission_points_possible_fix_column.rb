class SubmissionPointsPossibleFixColumn < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    change_column :quiz_submissions, :quiz_points_possible, :float
  end

  def self.down
    change_column :quiz_submissions, :quiz_points_possible, :integer
  end
end

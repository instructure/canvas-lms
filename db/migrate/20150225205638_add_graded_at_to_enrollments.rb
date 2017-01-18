class AddGradedAtToEnrollments < ActiveRecord::Migration
  tag :predeploy

  def change
    add_column :enrollments, :graded_at, :datetime
  end
end

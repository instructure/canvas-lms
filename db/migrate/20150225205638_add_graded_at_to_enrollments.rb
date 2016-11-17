class AddGradedAtToEnrollments < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :enrollments, :graded_at, :datetime
  end
end

class AddAssignmentGradesPublishedAt < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    add_column :assignments, :grades_published_at, :datetime
  end

  def down
    remove_column :assignments, :grades_published_at
  end
end

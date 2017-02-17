class AddGradedAnonymouslyToProvisionalGrade < ActiveRecord::Migration[4.2]
  tag :predeploy

  def change
    add_column :moderated_grading_provisional_grades, :graded_anonymously, :boolean
  end
end

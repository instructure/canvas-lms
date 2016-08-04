class AddGradedAnonymouslyToProvisionalGrade < ActiveRecord::Migration
  tag :predeploy

  def change
    add_column :moderated_grading_provisional_grades, :graded_anonymously, :boolean
  end
end

class AddQuestionReferencesFixedColumnToQuizSubmissions < ActiveRecord::Migration
  tag :predeploy

  def change
    add_column :quiz_submissions, :question_references_fixed, :boolean
  end
end

class AddAqIndexToQuizQuestions < ActiveRecord::Migration
  disable_ddl_transaction!
  tag :postdeploy

  def change
    add_index :quiz_questions, :assessment_question_id, where: "assessment_question_id IS NOT NULL", algorithm: :concurrently
  end
end

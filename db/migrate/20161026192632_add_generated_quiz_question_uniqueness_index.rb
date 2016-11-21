class AddGeneratedQuizQuestionUniquenessIndex < ActiveRecord::Migration
  tag :predeploy
  disable_ddl_transaction!

  def change
    add_column :quiz_questions, :duplicate_index, :integer
    add_index :quiz_questions, [:assessment_question_id, :quiz_group_id, :duplicate_index],
              name: "index_generated_quiz_questions",
              where: "assessment_question_id IS NOT NULL AND quiz_group_id IS NOT NULL AND workflow_state='generated'",
              unique: true,
              algorithm: :concurrently
  end
end

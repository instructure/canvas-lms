class AddLookupIndexToQuizQuestions < ActiveRecord::Migration
  tag :predeploy
  disable_ddl_transaction!

  def up
    remove_index :quiz_questions, name: "index_quiz_questions_on_assessment_question_id"
    remove_index :quiz_questions, name: "index_quiz_questions_on_quiz_id"

    # we'll need the composite index when pulling questions out of a bank,
    # otherwise all queries use the quiz_id and would utilize this index
    add_index :quiz_questions, [ :quiz_id, :assessment_question_id ], {
      name: 'idx_qqs_on_quiz_and_aq_ids',
      algorithm: :concurrently
    }
  end

  def down
    add_index :quiz_questions, :assessment_question_id, {
      name: "index_quiz_questions_on_assessment_question_id",
      algorithm: :concurrently
    }

    add_index :quiz_questions, :quiz_id, {
      name: "index_quiz_questions_on_quiz_id",
      algorithm: :concurrently
    }

    remove_index :quiz_questions, :name => 'idx_qqs_on_quiz_and_aq_ids'
  end
end

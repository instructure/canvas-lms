class AddIndicesToQuizSubmissionEvents < CanvasPartman::Migration
  tag :predeploy

  self.master_table = :quiz_submission_events
  self.base_class = Quizzes::QuizSubmissionEvent

  def up
    with_each_partition do |partition|
      index_ns = partition.sub('quiz_submission_events', 'qse')

      add_index partition, :created_at,
        name: "#{index_ns}_idx_on_created_at"

      add_index partition, [ :quiz_submission_id, :attempt, :created_at ],
        name: "#{index_ns}_predecessor_locator_idx"

      add_foreign_key partition, :quiz_submissions
    end
  end

  def down
    with_each_partition do |partition|
      index_ns = partition.sub('quiz_submission_events', 'qse')

      remove_index partition, name: "#{index_ns}_idx_on_created_at"
      remove_index partition, name: "#{index_ns}_predecessor_locator_idx"

      remove_foreign_key partition, :quiz_submissions
    end
  end
end

class SetDefaultValuesForQuizzes < ActiveRecord::Migration[4.2]
  tag :predeploy
  disable_ddl_transaction!

  def up
    default_false_fields = [
      :shuffle_answers, :could_be_locked, :anonymous_submissions,
      :require_lockdown_browser, :require_lockdown_browser_for_results,
      :one_question_at_a_time, :cant_go_back, :require_lockdown_browser_monitor,
      :only_visible_to_overrides, :one_time_results, :show_correct_answers_last_attempt
    ]
    default_false_fields.each { |field| change_column_default(:quizzes, field, false) }
    change_column_default(:quizzes, :show_correct_answers, true)
    DataFixup::BackfillNulls.run(Quizzes::Quiz, default_false_fields, default_value: false)
    DataFixup::BackfillNulls.run(Quizzes::Quiz, [:show_correct_answers], default_value: true)
    not_null_fields = default_false_fields + [:show_correct_answers]
    not_null_fields.each { |field| change_column_null_with_less_locking(:quizzes, field) }
  end

  def down
    fields = [
      :shuffle_answers, :could_be_locked, :anonymous_submissions,
      :require_lockdown_browser, :require_lockdown_browser_for_results,
      :one_question_at_a_time, :cant_go_back, :require_lockdown_browser_monitor,
      :only_visible_to_overrides, :one_time_results, :show_correct_answers_last_attempt,
      :show_correct_answers
    ]
    fields.each { |field| change_column_null(:quizzes, field, true) }
    fields.each { |field| change_column_default(:quizzes, field, nil) }
  end
end

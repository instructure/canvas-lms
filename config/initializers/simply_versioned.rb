Rails.configuration.to_prepare do
  reflection = Version.reflections[CANVAS_RAILS4_0 ? :versionable : 'versionable']
  reflection.options[:exhaustive] = false
  reflection.options[:polymorphic] = [
    :assessment_question,
    :assignment,
    :assignment_override,
    :learning_outcome_question_result,
    :learning_outcome_result,
    :rubric,
    :rubric_assessment,
    :submission,
    :wiki_page,
    { quiz: 'Quizzes::Quiz',
      quiz_submission: 'Quizzes::QuizSubmission' }]
  Version.add_polymorph_methods(reflection)
end

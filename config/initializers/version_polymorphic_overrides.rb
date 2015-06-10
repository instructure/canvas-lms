Version.class_eval do
  include PolymorphicTypeOverride

  override_polymorphic_types versionable_type: {
    'Quiz' => 'Quizzes::Quiz',
    'QuizSubmission' => 'Quizzes::QuizSubmission'
  }
end

Feature.register('quiz_stats' => {
  display_name: -> {
    I18n.t('features.new_quiz_statistics', 'New Quiz Statistics Page')
  },
  description: -> {
    I18n.t 'new_quiz_statistics_desc',
      'Enable the new quiz statistics page for a course.'
  },
  applies_to: 'Course',
  state: 'allowed'
})
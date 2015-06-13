Feature.register('quiz_log_auditing' => {
  display_name: -> {
    I18n.t('features.quiz_log_auditing', 'Quiz Log Auditing')
  },
  description: -> {
    I18n.t 'quiz_log_auditing_desc', <<-TEXT
      Enable the tracking of events for a quiz submission, and the ability
      to view a log of those events once a submission is made.
    TEXT
  },
  applies_to: 'Course',
  beta: true
})
define({
  EVT_SESSION_STARTED: 'session_started',
  EVT_PAGE_FOCUSED: 'page_focused',
  EVT_PAGE_BLURRED: 'page_blurred',
  EVT_QUESTION_VIEWED: 'question_viewed',
  EVT_QUESTION_FLAGGED: 'question_flagged',
  EVT_QUESTION_ANSWERED: 'question_answered',

  EVT_FLAG_WARNING: 'warning',
  EVT_FLAG_OK: 'ok',

  EVENT_ATTRS: [
    'id',
    'event_type',
    'event_data',
    'created_at',
  ],

  EVENT_DATA_ATTRS: [
    'quiz_question_id',
    'answer'
  ],

  SUBMISSION_ATTRS: [
    'id',
    'started_at',
    'attempt'
  ],

  QUESTION_ATTRS: [
    'id',
    'question_type',
    'question_text',
    'position',
    'answers',
    'matches'
  ],

  Q_CALCULATED: 'calculated_question',
  Q_ESSAY: 'essay_question',
  Q_FILE_UPLOAD: 'file_upload_question',
  Q_FILL_IN_MULTIPLE_BLANKS: 'fill_in_multiple_blanks_question',
  Q_MATCHING: 'matching_question',
  Q_MULTIPLE_ANSWERS: 'multiple_answers_question',
  Q_MULTIPLE_CHOICE: 'multiple_choice_question',
  Q_MULTIPLE_DROPDOWNS: 'multiple_dropdowns_question',
  Q_TRUE_FALSE: 'true_false_question',
  Q_NUMERICAL: 'numerical_question',
  Q_SHORT_ANSWER: 'short_answer_question',

  // Answer text longer than this will be truncated for questions of types
  // "essay" and other free-form input ones. This applies to the table view.
  MAX_VISIBLE_CHARS: 50
});

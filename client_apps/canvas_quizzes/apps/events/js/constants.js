define({
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
});
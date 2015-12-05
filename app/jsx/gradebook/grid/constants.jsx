define([
  'underscore'
], function (_) {
  var GRADEBOOK_CONSTANTS = {
    STUDENT_COLUMN_ID: 'student',
    NOTES_COLUMN_ID: 'notes',
    PERCENT_COLUMN_ID: 'percent',
    PASS_FAIL_COLUMN_ID: 'pass_fail',
    LETTER_GRADE_COLUMN_ID: 'letter_grade',
    POINTS_COLUMN_ID: 'points',
    GPA_SCALE_COLUMN_ID: 'gpa_scale',
    TOTAL_COLUMN_ID: 'total',
    CUSTOM_COLUMN_ID: 'custom',
    ASSIGNMENT_GROUP_COLUMN_ID: 'assignment_group',
    MOUNT_ELEMENT: document.getElementById('gradebook-grid-wrapper'),
    DEFAULT_LAYOUTS: {
      headers: { width: 150, height: 40, flexGrow: 0, paddingAdjustment: 20 },
      rows: { height: 36 }
    },
    SUBMISSION_RESPONSE_FIELDS: [
      'id',
      'user_id',
      'url',
      'score',
      'grade',
      'submission_type',
      'submitted_at',
      'assignment_id',
      'grade_matches_current_submission',
      'attachments',
      'late',
      'workflow_state'
    ],
    DEFAULT_TOOLBAR_PREFERENCES: {
      hideStudentNames: false,
      hideNotesColumn: true,
      treatUngradedAsZero: false,
      totalColumnInFront: false,
      arrangeColumnsBy: 'assignment_group',
      warnedAboutTotalsDisplay: false,
      showTotalGradeAsPoints: false
    },
    ASSIGNMENT_DATES: ['created_at', 'updated_at', 'due_at', 'lock_at', 'unlock_at'],
    OVERRIDE_DATES: ['all_day_date', 'due_at', 'lock_at', 'unlock_at'],
    PAGINATION_COUNT: 50,
    MAX_NOTE_LENGTH: 255,
    // keyboard codes: tab, enter, left arrow, up arrow, right arrow, down arrow
    RECOGNIZED_KEYBOARD_CODES: [9,13,37,38,39,40],
    refresh: function() {
      // For testing
      _.extend(this, ENV.GRADEBOOK_OPTIONS);
    }
  };

  var CONSTANTS = _.extend({}, GRADEBOOK_CONSTANTS, ENV.GRADEBOOK_OPTIONS);

  return CONSTANTS;
});

define([
  'helpers/fakeENV',
  'grade_summary'
], (fakeENV, grade_summary) => {
  module('grade_summary#calculateTotals', {
    setup() {
      fakeENV.setup();

      this.screenReaderFlashMessageExclusive = this.stub($, 'screenReaderFlashMessageExclusive');
      $('#fixtures').html('<div class="grade changed"></div>');

      this.currentOrFinal = 'current';
      this.groupWeightingScheme = null;
      this.calculatedGrades = {
        'group_sums': [
          {
            'group': {
              'id': '1',
              'rules': {},
              'group_weight': 0,
              'assignments': [
                {
                  'id': '4',
                  'submission_types': ['none'],
                  'points_possible': 10,
                  'due_at': '2017-01-03T06:59:00Z',
                  'omit_from_final_grade': false
                }, {
                  'id': '3',
                  'submission_types': ['none'],
                  'points_possible': 10,
                  'due_at': '2016-12-26T06:59:00Z',
                  'omit_from_final_grade': false
                }
              ]
            },
            'current': {
              'possible': 0,
              'score': 0,
              'submission_count': 0,
              'submissions': [
                {
                  'percent': 0,
                  'possible': 10,
                  'score': 0,
                  'submission': {
                    'assignment_id': '4',
                    'score': null,
                    'excused': false,
                    'workflow_state': 'unsubmitted'
                  },
                  'submitted': false
                },
                {
                  'percent': 0,
                  'possible': 10,
                  'score': 0,
                  'submission': {
                    'assignment_id': '3',
                    'score': null,
                    'excused': false,
                    'workflow_state': 'unsubmitted'
                  },
                  'submitted': false
                }
              ],
              'weight': 0
            },
            'final': {
              'possible': 20,
              'score': 0,
              'submission_count': 0,
              'submissions': [
                {
                  'percent': 0,
                  'possible': 10,
                  'score': 0,
                  'submission': {
                    'assignment_id': '4',
                    'score': null,
                    'excused': false,
                    'workflow_state': 'unsubmitted'
                  },
                  'submitted': false
                },
                {
                  'percent': 0,
                  'possible': 10,
                  'score': 0,
                  'submission': {
                    'assignment_id': '3',
                    'score': null,
                    'excused': false,
                    'workflow_state': 'unsubmitted'
                  },
                  'submitted': false
                }
              ],
              'weight': 0
            }
          }
        ],
        'current': {
          'score': 0,
          'possible': 0
        },
        'final': {
          'score': 0,
          'possible': 20
        }
      };
    },

    teardown() {
      fakeENV.teardown();
    }
  });

  test('generates a screenreader-only alert when grades have been changed', function() {
    grade_summary.calculateTotals(this.calculatedGrades, this.currentOrFinal, this.groupWeightingScheme);

    ok(this.screenReaderFlashMessageExclusive.calledOnce);
  });

  test('does not generate a screenreader-only alert when grades are unchanged', function() {
    $('#fixtures').html('');
    grade_summary.calculateTotals(this.calculatedGrades, this.currentOrFinal, this.groupWeightingScheme);

    notOk(this.screenReaderFlashMessageExclusive.called);
  });
});

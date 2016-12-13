define([
  'jquery',
  'helpers/fakeENV',
  'jsx/gradebook/CourseGradeCalculator',
  'grade_summary'
], ($, fakeENV, CourseGradeCalculator, grade_summary) => {
  module('grade_summary.calculateTotals', {
    setup () {
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

    teardown () {
      fakeENV.teardown();
    }
  });

  test('generates a screenreader-only alert when grades have been changed', function () {
    grade_summary.calculateTotals(this.calculatedGrades, this.currentOrFinal, this.groupWeightingScheme);

    ok(this.screenReaderFlashMessageExclusive.calledOnce);
  });

  test('does not generate a screenreader-only alert when grades are unchanged', function () {
    $('#fixtures').html('');
    grade_summary.calculateTotals(this.calculatedGrades, this.currentOrFinal, this.groupWeightingScheme);

    notOk(this.screenReaderFlashMessageExclusive.called);
  });

  module('grade_summary.calculateGrades', {
    setup () {
      fakeENV.setup();
      ENV.submissions = [{ assignment_id: 201, score: 10 }];
      const assignments = [{ id: 201, points_possible: 10, omit_from_final_grade: false }];
      ENV.assignment_groups = [{ id: 301, group_weight: 60, rules: {}, assignments }];
      ENV.group_weighting_scheme = 'points';
      ENV.grading_periods = [{ id: 701, weight: 50 }, { id: 702, weight: 50 }];
      ENV.effective_due_dates = { 201: { 101: { grading_period_id: '701' } } };
      ENV.student_id = '101';
    },

    teardown () {
      fakeENV.teardown();
    }
  });

  test('calculates grades using data in the env', function () {
    this.stub(CourseGradeCalculator, 'calculate').returns('expected');
    const grades = grade_summary.calculateGrades();
    equal(grades, 'expected');
    const args = CourseGradeCalculator.calculate.getCall(0).args;
    equal(args[0], ENV.submissions);
    equal(args[1], ENV.assignment_groups);
    equal(args[2], ENV.group_weighting_scheme);
    equal(args[3], ENV.grading_periods);
  });

  test('scopes effective due dates to the user', function () {
    this.stub(CourseGradeCalculator, 'calculate');
    grade_summary.calculateGrades();
    const dueDates = CourseGradeCalculator.calculate.getCall(0).args[4];
    deepEqual(dueDates, { 201: { grading_period_id: '701' } });
  });

  test('calculates grades without grading period data when effective due dates are not defined', function () {
    delete ENV.effective_due_dates;
    this.stub(CourseGradeCalculator, 'calculate');
    grade_summary.calculateGrades();
    const args = CourseGradeCalculator.calculate.getCall(0).args;
    equal(args[0], ENV.submissions);
    equal(args[1], ENV.assignment_groups);
    equal(args[2], ENV.group_weighting_scheme);
    equal(args[3], undefined);
    equal(args[4], undefined);
  });
});

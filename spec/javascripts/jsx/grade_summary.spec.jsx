/**
 * Copyright (C) 2017 Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

define([
  'i18n!gradebook',
  'lodash',
  'jquery',
  'helpers/fakeENV',
  'jsx/gradebook/CourseGradeCalculator',
  'grade_summary'
], (i18n, _, $, fakeENV, CourseGradeCalculator, grade_summary) => { // eslint-disable-line camelcase
  function createAssignmentGroups () {
    return [
      { id: '301', assignments: [{ id: '201', muted: false }, { id: '202', muted: true }] },
      { id: '302', assignments: [{ id: '203', muted: true }] }
    ];
  }

  function createSubmissions () {
    return [
      { assignment_id: '201', score: 10 },
      { assignment_id: '203', score: 15 }
    ];
  }

  module('grade_summary#calculateTotals', {
    setup () {
      fakeENV.setup();

      this.screenReaderFlashMessageExclusive = this.stub($, 'screenReaderFlashMessageExclusive');
      $('#fixtures').html('<div class="grade changed"></div>');

      this.currentOrFinal = 'current';
      this.groupWeightingScheme = null;
      this.calculatedGrades = {
        group_sums: [
          {
            group: {
              id: '1',
              rules: {},
              group_weight: 0,
              assignments: [
                {
                  id: '4',
                  submission_types: ['none'],
                  points_possible: 10,
                  due_at: '2017-01-03T06:59:00Z',
                  omit_from_final_grade: false
                }, {
                  id: '3',
                  submission_types: ['none'],
                  points_possible: 10,
                  due_at: '2016-12-26T06:59:00Z',
                  omit_from_final_grade: false
                }
              ]
            },
            current: {
              possible: 0,
              score: 0,
              submission_count: 0,
              submissions: [
                {
                  percent: 0,
                  possible: 10,
                  score: 0,
                  submission: {
                    assignment_id: '4',
                    score: null,
                    excused: false,
                    workflow_state: 'unsubmitted'
                  },
                  submitted: false
                },
                {
                  percent: 0,
                  possible: 10,
                  score: 0,
                  submission: {
                    assignment_id: '3',
                    score: null,
                    excused: false,
                    workflow_state: 'unsubmitted'
                  },
                  submitted: false
                }
              ],
              weight: 0
            },
            final: {
              possible: 20,
              score: 0,
              submission_count: 0,
              submissions: [
                {
                  percent: 0,
                  possible: 10,
                  score: 0,
                  submission: {
                    assignment_id: '4',
                    score: null,
                    excused: false,
                    workflow_state: 'unsubmitted'
                  },
                  submitted: false
                },
                {
                  percent: 0,
                  possible: 10,
                  score: 0,
                  submission: {
                    assignment_id: '3',
                    score: null,
                    excused: false,
                    workflow_state: 'unsubmitted'
                  },
                  submitted: false
                }
              ],
              weight: 0
            }
          }
        ],
        current: {
          score: 0,
          possible: 0
        },
        final: {
          score: 0,
          possible: 20
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

  test('displays grades localized', function () {
    const sandbox = sinon.sandbox.create();
    sandbox.stub(i18n, 'n', function () { return 'I18n number'; });
    grade_summary.calculateTotals(this.calculatedGrades, this.currentOrFinal, this.groupWeightingScheme);

    notOk($('.score_teaser').text().indexOf('I18n number') === -1);

    sandbox.restore();
  });

  module('grade_summary.canBeConvertedToGrade');

  test('returns false when possible is nonpositive', function () {
    notOk(grade_summary.canBeConvertedToGrade(1, 0));
  });

  test('returns false when score is NaN', function () {
    notOk(grade_summary.canBeConvertedToGrade(NaN, 1));
  });

  test('returns true when score is a number and possible is positive', function () {
    ok(grade_summary.canBeConvertedToGrade(1, 1));
  });

  module('grade_summary.calculatePercentGrade');

  test('returns properly computed and rounded value', function () {
    const percentGrade = grade_summary.calculatePercentGrade(1, 3);
    ok(percentGrade === 33.33);
  });

  module('grade_summary.formatPercentGrade');

  test('returns i18ned number value', function () {
    const sandbox = sinon.sandbox.create();
    sandbox.stub(i18n, 'n', function () { return 'formatted number'; });
    const formattedPercentGrade = grade_summary.formatPercentGrade(33.33);

    ok(formattedPercentGrade === 'formatted number');

    sandbox.restore();
  });

  module('grade_summary.calculateGrade');

  test('returns N/A when canBeConvertedToGrade returns false', function () {
    const sandbox = sinon.sandbox.create();
    sandbox.stub(grade_summary, 'canBeConvertedToGrade', function () { return false; });
    const calculatedGrade = grade_summary.calculateGrade(1, 1);

    ok(calculatedGrade === 'N/A');

    sandbox.restore();
  });

  test('composes formatPercentGrade and calculatePercentGrade', function () {
    const sandbox = sinon.sandbox.create();
    sandbox.stub(grade_summary, 'calculatePercentGrade', function () { return 'percentGrade'; });
    sandbox.stub(grade_summary, 'formatPercentGrade', function (val) { return `formatted:${val}`; });
    const calculatedGrade = grade_summary.calculateGrade(1, 1);

    ok(calculatedGrade === 'formatted:percentGrade');

    sandbox.restore();
  });

  module('grade_summary.listAssignmentGroupsForGradeCalculation', {
    setup () {
      fakeENV.setup();
      ENV.assignment_groups = createAssignmentGroups();
    },

    teardown () {
      fakeENV.teardown();
    }
  });

  test('excludes muted assignments when no "What-If" grades exist', function () {
    const assignmentGroups = grade_summary.listAssignmentGroupsForGradeCalculation();
    equal(assignmentGroups.length, 2);
    equal(assignmentGroups[0].assignments.length, 1);
    equal(assignmentGroups[1].assignments.length, 0);
  });

  test('includes muted assignments where "What-If" grades exist', function () {
    grade_summary.addWhatIfAssignment('203');
    let assignmentGroups = grade_summary.listAssignmentGroupsForGradeCalculation();
    equal(assignmentGroups[0].assignments.length, 1);
    equal(assignmentGroups[1].assignments.length, 1);
    grade_summary.addWhatIfAssignment('202');
    assignmentGroups = grade_summary.listAssignmentGroupsForGradeCalculation();
    equal(assignmentGroups[0].assignments.length, 2);
    equal(assignmentGroups[1].assignments.length, 1);
  });

  test('excludes muted assignments previously with "What-If" grades', function () {
    grade_summary.addWhatIfAssignment('202');
    grade_summary.addWhatIfAssignment('203');
    let assignmentGroups = grade_summary.listAssignmentGroupsForGradeCalculation();
    equal(assignmentGroups[0].assignments.length, 2);
    equal(assignmentGroups[1].assignments.length, 1);
    grade_summary.removeWhatIfAssignment('202');
    assignmentGroups = grade_summary.listAssignmentGroupsForGradeCalculation();
    equal(assignmentGroups[0].assignments.length, 1);
    equal(assignmentGroups[1].assignments.length, 1);
  });

  module('grade_summary.calculateGrades', {
    setup () {
      fakeENV.setup();
      ENV.submissions = createSubmissions();
      ENV.assignment_groups = createAssignmentGroups();
      ENV.group_weighting_scheme = 'points';
      this.stub(CourseGradeCalculator, 'calculate').returns('expected');
    },

    teardown () {
      fakeENV.teardown();
    }
  });

  test('calculates grades using data in the env', function () {
    grade_summary.calculateGrades();
    const args = CourseGradeCalculator.calculate.getCall(0).args;
    equal(args[0], ENV.submissions);
    deepEqual(_.map(args[1], 'id'), ['301', '302']);
    equal(args[2], ENV.group_weighting_scheme);
  });

  test('returns the result of grade calculation from the grade calculator', function () {
    const grades = grade_summary.calculateGrades();
    equal(grades, 'expected');
  });

  test('includes muted assignments where "What-If" grades exist', function () {
    grade_summary.addWhatIfAssignment('202');
    grade_summary.addWhatIfAssignment('203');
    grade_summary.calculateGrades();
    const assignmentGroups = CourseGradeCalculator.calculate.getCall(0).args[1];
    equal(assignmentGroups[0].assignments.length, 2);
    equal(assignmentGroups[1].assignments.length, 1);
  });
});

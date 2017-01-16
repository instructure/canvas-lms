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
  'lodash',
  'jquery',
  'helpers/fakeENV',
  'spec/jsx/gradebook/GradeCalculatorSpecHelper',
  'jsx/gradebook/CourseGradeCalculator',
  'grade_summary'
], (
  _, $, fakeENV, GradeCalculatorSpecHelper, CourseGradeCalculator, grade_summary // eslint-disable-line camelcase
) => {
  let exampleGrades;

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

  module('grade_summary.getGradingPeriodSet', {
    setup () {
      fakeENV.setup();
    },

    teardown () {
      fakeENV.teardown();
    }
  });

  test('normalizes the grading period set from the env', function () {
    ENV.grading_period_set = {
      id: 1501,
      grading_periods: [{ id: 701, weight: 50 }, { id: 702, weight: 50 }],
      weighted: true
    };
    const gradingPeriodSet = grade_summary.getGradingPeriodSet();
    deepEqual(gradingPeriodSet.id, '1501');
    equal(gradingPeriodSet.gradingPeriods.length, 2);
    deepEqual(_.map(gradingPeriodSet.gradingPeriods, 'id'), ['701', '702']);
  });

  test('returns null when the grading period set is not defined in the env', function () {
    ENV.grading_period_set = undefined;
    const gradingPeriodSet = grade_summary.getGradingPeriodSet();
    deepEqual(gradingPeriodSet, null);
  });

  module('grade_summary.calculateTotals', {
    setup () {
      fakeENV.setup();
      ENV.assignment_groups = createAssignmentGroups();

      this.screenReaderFlashMessageExclusive = this.stub($, 'screenReaderFlashMessageExclusive');
      $('#fixtures').html('<div class="grade changed"></div>');

      this.currentOrFinal = 'current';
      this.groupWeightingScheme = null;
      this.calculatedGrades = {
        assignmentGroups: {},
        current: { score: 0, possible: 0 },
        final: { score: 0, possible: 20 }
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
      ENV.grading_period_set = {
        id: 1501,
        grading_periods: [{ id: 701, weight: 50 }, { id: 702, weight: 50 }],
        weighted: true
      };
      ENV.effective_due_dates = { 201: { 101: { grading_period_id: '701' } } };
      ENV.student_id = '101';
      exampleGrades = GradeCalculatorSpecHelper.createCourseGradesWithGradingPeriods();
      this.stub(CourseGradeCalculator, 'calculate').returns(exampleGrades);
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

  test('normalizes the grading period set before calculation', function () {
    grade_summary.calculateGrades();
    const gradingPeriodSet = CourseGradeCalculator.calculate.getCall(0).args[3];
    deepEqual(gradingPeriodSet.id, '1501');
    equal(gradingPeriodSet.gradingPeriods.length, 2);
    deepEqual(_.map(gradingPeriodSet.gradingPeriods, 'id'), ['701', '702']);
  });

  test('scopes effective due dates to the user', function () {
    grade_summary.calculateGrades();
    const dueDates = CourseGradeCalculator.calculate.getCall(0).args[4];
    deepEqual(dueDates, { 201: { grading_period_id: '701' } });
  });

  test('calculates grades without grading period data when the grading period set is not defined', function () {
    delete ENV.grading_period_set;
    grade_summary.calculateGrades();
    const args = CourseGradeCalculator.calculate.getCall(0).args;
    equal(args[0], ENV.submissions);
    equal(args[1], ENV.assignment_groups);
    equal(args[2], ENV.group_weighting_scheme);
    equal(typeof args[3], 'undefined');
    equal(typeof args[4], 'undefined');
  });

  test('calculates grades without grading period data when effective due dates are not defined', function () {
    delete ENV.effective_due_dates;
    grade_summary.calculateGrades();
    const args = CourseGradeCalculator.calculate.getCall(0).args;
    equal(args[0], ENV.submissions);
    equal(args[1], ENV.assignment_groups);
    equal(args[2], ENV.group_weighting_scheme);
    equal(typeof args[3], 'undefined');
    equal(typeof args[4], 'undefined');
  });

  test('includes muted assignments where "What-If" grades exist', function () {
    grade_summary.addWhatIfAssignment('202');
    grade_summary.addWhatIfAssignment('203');
    grade_summary.calculateGrades();
    const assignmentGroups = CourseGradeCalculator.calculate.getCall(0).args[1];
    equal(assignmentGroups[0].assignments.length, 2);
    equal(assignmentGroups[1].assignments.length, 1);
  });

  test('returns course grades when no grading period id is provided', function () {
    this.stub(grade_summary, 'getGradingPeriodIdFromUrl').returns(null);
    const grades = grade_summary.calculateGrades();
    equal(grades, exampleGrades);
  });

  test('scopes grades to the provided grading period id', function () {
    this.stub(grade_summary, 'getGradingPeriodIdFromUrl').returns('701');
    const grades = grade_summary.calculateGrades();
    equal(grades, exampleGrades.gradingPeriods[701]);
  });

  module('grade_summary.getGradingPeriodIdFromUrl');

  test('returns the value for grading_period_id in the url', function () {
    const url = 'example.com/course/1/grades?grading_period_id=701';
    equal(grade_summary.getGradingPeriodIdFromUrl(url), '701');
  });

  test('returns null when grading_period_id is set to "0"', function () {
    const url = 'example.com/course/1/grades?grading_period_id=0';
    deepEqual(grade_summary.getGradingPeriodIdFromUrl(url), null);
  });

  test('returns null when grading_period_id is not present in the url', function () {
    const url = 'example.com/course/1/grades';
    deepEqual(grade_summary.getGradingPeriodIdFromUrl(url), null);
  });
});

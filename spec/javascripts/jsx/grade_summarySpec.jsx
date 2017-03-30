/**
 * Copyright (C) 2016 - 2017 Instructure, Inc.
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
  'i18n!gradebook',
  'spec/jsx/gradebook/GradeCalculatorSpecHelper',
  'jsx/gradebook/CourseGradeCalculator',
  'grade_summary'
], (
  _, $, fakeENV, I18n, GradeCalculatorSpecHelper, CourseGradeCalculator,
  grade_summary // eslint-disable-line camelcase
) => {
  const $fixtures = $('#fixtures');

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

  function createExampleGrades () {
    return {
      assignmentGroups: {},
      current: {
        score: 0,
        possible: 0
      },
      final: {
        score: 0,
        possible: 20
      }
    };
  }

  function setPageHtmlFixture () {
    $fixtures.html(`
      <select class="grading_periods_selector">
        <option value="0" selected>All Grading Periods</option>
        <option value="701">Grading Period 1</option>
        <option value="702">Grading Period 2</option>
      </select>
      <div id="grade_summary_fixture">
        <div class="student_assignment final_grade">
          <span class="grade"></span>
          <span class="score_teaser"></span>
        </div>
        <button id="show_all_details_button">Show All Details</button>
        <span id="aria-announcer"></span>
        <table class="grades_summary">
          <tr>
            <td class="assignment_score">
              <span class="grade"></span>
              <span class="score_teaser"></span>
            </td>
          </tr>
        </table>
        <span id="aria-announcer"></span>
      </div>
    `);
  }

  function commonSetup () {
    fakeENV.setup();
    $fixtures.html('');
  }

  function commonTeardown () {
    fakeENV.teardown();
  }

  QUnit.module('grade_summary.getGradingPeriodSet', {
    setup () {
      commonSetup();
    },

    teardown () {
      commonTeardown();
    }
  });

  test('normalizes the grading period set from the env', function () {
    ENV.grading_period_set = {
      id: '1501',
      grading_periods: [{ id: '701', weight: 50 }, { id: '702', weight: 50 }],
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

  QUnit.module('grade_summary.calculateTotals', {
    setup () {
      commonSetup();
      ENV.assignment_groups = createAssignmentGroups();
      this.stub($, 'screenReaderFlashMessageExclusive');
      setPageHtmlFixture();
    },

    teardown () {
      commonTeardown();
    }
  });

  test('displays a screenreader-only alert when grades have been changed', function () {
    $fixtures.find('.assignment_score .grade').addClass('changed');
    grade_summary.calculateTotals(createExampleGrades(), 'current', 'percent');
    equal($.screenReaderFlashMessageExclusive.callCount, 1);
    const messageText = $.screenReaderFlashMessageExclusive.getCall(0).args[0];
    ok(messageText.includes('the new total is now'), 'flash message mentions new total');
  });

  test('does not display a screenreader-only alert when grades have not been changed', function () {
    grade_summary.calculateTotals(createExampleGrades(), 'current', 'percent');
    equal($.screenReaderFlashMessageExclusive.callCount, 0);
  });

  test('localizes displayed grade', function () {
    this.stub(I18n, 'n').returns('1,234');
    grade_summary.calculateTotals(createExampleGrades(), 'current', 'percent');
    const $teaser = $fixtures.find('.student_assignment.final_grade .score_teaser');
    ok($teaser.text().includes('1,234'), 'includes internationalized score');
  });

  QUnit.module('grade_summary.canBeConvertedToGrade');

  test('returns false when possible is nonpositive', function () {
    notOk(grade_summary.canBeConvertedToGrade(1, 0));
  });

  test('returns false when score is NaN', function () {
    notOk(grade_summary.canBeConvertedToGrade(NaN, 1));
  });

  test('returns true when score is a number and possible is positive', function () {
    ok(grade_summary.canBeConvertedToGrade(1, 1));
  });

  QUnit.module('grade_summary.calculatePercentGrade');

  test('returns properly computed and rounded value', function () {
    const percentGrade = grade_summary.calculatePercentGrade(1, 3);
    ok(percentGrade === 33.33);
  });

  QUnit.module('grade_summary.formatPercentGrade');

  test('returns an internationalized number value', function () {
    this.stub(I18n, 'n').withArgs(1234).returns('1,234%');
    equal(grade_summary.formatPercentGrade(1234), '1,234%');
  });

  QUnit.module('grade_summary.calculateGrade');

  test('returns an internationalized percentage when given a score and nonzero points possible', function () {
    this.stub(I18n, 'n').callsFake(number => `${number}%`);
    equal(grade_summary.calculateGrade(97, 100), '97%');
    equal(I18n.n.getCall(0).args[1].percentage, true);
  });

  test('returns "N/A" when given a numerical score and zero points possible', function () {
    equal(grade_summary.calculateGrade(1, 0), 'N/A');
  });

  test('returns "N/A" when given a non-numerical score and nonzero points possible', function () {
    equal(grade_summary.calculateGrade(undefined, 1), 'N/A');
  });

  QUnit.module('grade_summary.listAssignmentGroupsForGradeCalculation', {
    setup () {
      commonSetup();
      ENV.assignment_groups = createAssignmentGroups();
    },

    teardown () {
      commonTeardown();
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

  QUnit.module('grade_summary.calculateGrades', {
    setup () {
      commonSetup();
      ENV.submissions = createSubmissions();
      ENV.assignment_groups = createAssignmentGroups();
      ENV.group_weighting_scheme = 'points';
      ENV.grading_period_set = {
        id: '1501',
        grading_periods: [{ id: '701', weight: 50 }, { id: '702', weight: 50 }],
        weighted: true
      };
      ENV.effective_due_dates = { 201: { 101: { grading_period_id: '701' } } };
      ENV.student_id = '101';
      exampleGrades = GradeCalculatorSpecHelper.createCourseGradesWithGradingPeriods();
      this.stub(CourseGradeCalculator, 'calculate').returns(exampleGrades);
    },

    teardown () {
      commonTeardown();
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
    this.stub(grade_summary, 'getSelectedGradingPeriodId').returns(null);
    const grades = grade_summary.calculateGrades();
    equal(grades, exampleGrades);
  });

  test('scopes grades to the provided grading period id', function () {
    this.stub(grade_summary, 'getSelectedGradingPeriodId').returns('701');
    const grades = grade_summary.calculateGrades();
    equal(grades, exampleGrades.gradingPeriods[701]);
  });

  QUnit.module('Grade Summary "Show All Details" button', {
    setup () {
      fakeENV.setup();
      setPageHtmlFixture();
      ENV.submissions = createSubmissions();
      ENV.assignment_groups = createAssignmentGroups();
      ENV.group_weighting_scheme = 'points';
      grade_summary.setup();
    },

    teardown () {
      commonTeardown();
    }
  });

  test('announces "assignment details expanded" when clicked', function () {
    $('#show_all_details_button').click();
    equal($('#aria-announcer').text(), 'assignment details expanded');
  });

  test('changes text to "Hide All Details" when clicked', function () {
    $('#show_all_details_button').click();
    equal($('#show_all_details_button').text(), 'Hide All Details');
  });

  test('announces "assignment details collapsed" when clicked and already expanded', function () {
    $('#show_all_details_button').click();
    $('#show_all_details_button').click();
    equal($('#aria-announcer').text(), 'assignment details collapsed');
  });

  test('changes text to "Show All Details" when clicked twice', function () {
    $('#show_all_details_button').click();
    $('#show_all_details_button').click();
    equal($('#show_all_details_button').text(), 'Show All Details');
  });

  QUnit.module('grade_summary.getSelectedGradingPeriodId', {
    setup () {
      this.$select = document.querySelector('.grading_periods_selector');
    }
  });

  test('returns the value of the selected grading period', function () {
    this.$select.value = '701';
    equal(grade_summary.getSelectedGradingPeriodId(), '701');
  });

  test('returns null when "All Grading Periods" is selected', function () {
    this.$select.value = '0';
    deepEqual(grade_summary.getSelectedGradingPeriodId(), null);
  });

  test('returns null when the grading periods selector is not present in the DOM', function () {
    this.$select.parentNode.removeChild(this.$select);
    deepEqual(grade_summary.getSelectedGradingPeriodId(), null);
  });
});

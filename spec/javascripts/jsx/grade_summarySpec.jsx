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
  'i18n!gradebook',
  'helpers/fakeENV',
  'spec/jsx/gradebook/GradeCalculatorSpecHelper',
  'jsx/gradebook/CourseGradeCalculator',
  'grade_summary'
], (
  _, $, I18n, fakeENV, GradeCalculatorSpecHelper, CourseGradeCalculator,
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
      <div id="grade_summary_fixture">
        <div class="student_assignment final_grade">
          <span class="grade"></span>
          <span class="score_teaser"></span>
        </div>
        <button id="show_all_details_button">Show All Details</button>
        <span id="aria-announcer"></span>
        <table id="grades_summary" class="editable">
          <tr class="student_assignment editable">
            <td class="assignment_score" title="Click to test a different score">
              <div class="score_holder">
                <span class="tooltip">
                  <span class="tooltip_wrap">
                    <span class="tooltip_text score_teaser">Click to test a different score</span>
                  </span>
                  <span class="grade">
                    <span class="screenreader-only">Click to test a different score</span>
                  </span>
                  <span class="score_value">A</span>
                </span>
                <span>
                  <span class="what_if_score"></span>
                  <span class="assignment_id">201</span>
                  <span class="student_entered_score"></span>
                </span>
              </div>
            </td>
          </tr>
        </table>
        <input type="text" id="grade_entry" style="display: none;" />
        <a id="revert_score_template" class="revert_score_link" >Revert Score</i></a>
        <a href="/assignments/{{ assignment_id }}" class="update_submission_url">&nbsp;</a>
      </div>
    `);
  }

  function commonSetup () {
    fakeENV.setup();
    $fixtures.html('');
  }

  function fullPageSetup () {
    fakeENV.setup();
    setPageHtmlFixture();
    ENV.submissions = createSubmissions();
    ENV.assignment_groups = createAssignmentGroups();
    ENV.group_weighting_scheme = 'points';
    grade_summary.setup();
  }

  function commonTeardown () {
    fakeENV.teardown();
    $fixtures.html('');
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
    this.stub(grade_summary, 'getGradingPeriodIdFromUrl').returns(null);
    const grades = grade_summary.calculateGrades();
    equal(grades, exampleGrades);
  });

  test('scopes grades to the provided grading period id', function () {
    this.stub(grade_summary, 'getGradingPeriodIdFromUrl').returns('701');
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

  QUnit.module('grade_summary.getGradingPeriodIdFromUrl');

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

  QUnit.module('grade_summary - Editing a "What-If" Score', {
    setup () {
      fullPageSetup();
      $fixtures.find('.assignment_score .grade').first().append('5');
    },

    onEditWhatIfScore () {
      const $assignmentScore = $fixtures.find('.assignment_score').first();
      $assignmentScore.trigger('click');
    },

    teardown () {
      commonTeardown();
    }
  });

  test('stores the original score when editing the the first time', function () {
    const $grade = $fixtures.find('.assignment_score .grade').first();
    const expectedHtml = $grade.html();
    this.onEditWhatIfScore();
    equal($grade.data('originalValue'), expectedHtml);
  });

  test('does not store the score when the original score is already stored', function () {
    const $grade = $fixtures.find('.assignment_score .grade').first();
    $grade.data('originalValue', '10');
    this.onEditWhatIfScore();
    equal($grade.data('originalValue'), '10');
  });

  test('attaches a screenreader-only element to the grade element as data', function () {
    this.onEditWhatIfScore();
    const $grade = $fixtures.find('.assignment_score .grade').first();
    ok($grade.data('screenreader_link'), '"screenreader_link" is assigned as data');
    ok($grade.data('screenreader_link').hasClass('screenreader-only'), '"screenreader_link" is screenreader-only');
  });

  test('hides the score value', function () {
    this.onEditWhatIfScore();
    const $scoreValue = $fixtures.find('.assignment_score .score_value').first();
    ok($scoreValue.is(':hidden'), '.score_value is hidden');
  });

  test('replaces the grade element content with a grade entry field', function () {
    this.onEditWhatIfScore();
    const $gradeEntry = $fixtures.find('.assignment_score .grade > #grade_entry');
    equal($gradeEntry.length, 1, '#grade_entry is attached to the .grade element');
  });

  test('sets the value of the grade entry to the existing "What-If" score', function () {
    $fixtures.find('.assignment_score').first().find('.what_if_score').text('15');
    this.onEditWhatIfScore();
    const $gradeEntry = $fixtures.find('#grade_entry').first();
    equal($gradeEntry.val(), '15', 'the previous "What-If" score is 15');
  });

  test('defaults the value of the grade entry to "0" when no score is present', function () {
    this.onEditWhatIfScore();
    const $gradeEntry = $fixtures.find('#grade_entry').first();
    equal($gradeEntry.val(), '0', 'there is no previous "What-If" score');
  });

  test('shows the grade entry', function () {
    this.onEditWhatIfScore();
    const $gradeEntry = $fixtures.find('#grade_entry').first();
    ok($gradeEntry.is(':visible'), '#grade_entry does not have "visibility: none"');
  });

  test('sets focus on the grade entry', function () {
    this.onEditWhatIfScore();
    const $gradeEntry = $fixtures.find('#grade_entry').first();
    equal($gradeEntry.get(0), document.activeElement, '#grade_entry is the active element');
  });

  test('selects the grade entry', function () {
    this.onEditWhatIfScore();
    const $gradeEntry = $fixtures.find('#grade_entry').get(0);
    equal($gradeEntry.selectionStart, 0, 'selection starts at beginning of score text');
    equal($gradeEntry.selectionEnd, 1, 'selection ends at end of score text');
  });

  test('announces message for entering a "What-If" score', function () {
    this.onEditWhatIfScore();
    equal($('#aria-announcer').text(), 'Enter a What-If score.');
  });

  QUnit.module('grade_summary.onScoreChange', {
    setup () {
      fullPageSetup();
      this.stub($, 'ajaxJSON');
      this.$assignment = $fixtures.find('#grades_summary .student_assignment').first();
      // reproduce the destructive part of .onEditWhatIfScore
      this.$assignment.find('.assignment_score').find('.grade').empty().append($('#grade_entry'));
    },

    onScoreChange (score, options = {}) {
      this.$assignment.find('#grade_entry').val(score);
      this.$assignment.triggerHandler('score_change', { update: false, refocus: false, ...options });
    },

    teardown () {
      commonTeardown();
    }
  });

  test('updates .what_if_score with the parsed value from #grade_entry', function () {
    this.onScoreChange('5');
    equal(this.$assignment.find('.what_if_score').text(), '5.0');
  });

  test('removes the .dont_update class from the .student_assignment element when present', function () {
    this.$assignment.addClass('dont_update');
    this.onScoreChange('5');
    notOk(this.$assignment.hasClass('dont_update'));
  });

  test('saves the "What-If" grade using the api', function () {
    this.onScoreChange('5', { update: true });
    equal($.ajaxJSON.callCount, 1, '$.ajaxJSON was called once');
    const [url, method, params] = $.ajaxJSON.getCall(0).args;
    equal(url, '/assignments/201', 'constructs the url from elements in the DOM');
    equal(method, 'PUT', 'uses PUT for updates');
    equal(params['submission[student_entered_score]'], 5);
  });

  test('updates the .student_entered_score element upon success api update', function () {
    $.ajaxJSON.callsFake((_url, _method, args, onSuccess) => {
      onSuccess({ submission: { student_entered_score: args['submission[student_entered_score]'] } });
    });
    this.onScoreChange('5', { update: true });
    equal(this.$assignment.find('.student_entered_score').text(), '5.0');
  });

  test('does not save the "What-If" grade when .dont_update class is present', function () {
    this.$assignment.addClass('dont_update');
    this.onScoreChange('5', { update: true });
    equal($.ajaxJSON.callCount, 0, '$.ajaxJSON was not called');
  });

  test('does not save the "What-If" grade when the "update" option is false', function () {
    this.onScoreChange('5', { update: false });
    equal($.ajaxJSON.callCount, 0, '$.ajaxJSON was not called');
  });

  test('hides the #grade_entry input', function () {
    this.onScoreChange('5');
    ok($('#grade_entry').is(':hidden'));
  });

  test('moves the #grade_entry to the body', function () {
    this.onScoreChange('5');
    ok($('#grade_entry').parent().is('body'));
  });

  test('sets the .assignment_score title to ""', function () {
    this.onScoreChange('5');
    equal(this.$assignment.find('.assignment_score').attr('title'), '');
  });

  test('sets the .assignment_score teaser text', function () {
    this.onScoreChange('5');
    equal(this.$assignment.find('.score_teaser').text(), 'This is a What-If score');
  });

  test('copies the "revert score" link into the .score_holder element', function () {
    this.onScoreChange('5');
    equal(this.$assignment.find('.score_holder .revert_score_link').length, 1, 'includes a "revert score" link');
    equal(this.$assignment.find('.score_holder .revert_score_link').text(), 'Revert Score');
  });

  test('adds the "changed" class to the .grade element', function () {
    this.onScoreChange('5');
    ok(this.$assignment.find('.grade').hasClass('changed'));
  });

  test('sets the .grade element content to the updated score', function () {
    this.onScoreChange('5');
    equal(this.$assignment.find('.grade').html(), '5.0');
  });

  test('sets the .grade element content to the previous score when the updated score is falsy', function () {
    this.$assignment.find('.grade').data('originalValue', '10.0');
    this.onScoreChange('');
    equal(this.$assignment.find('.grade').html(), '10.0');
  });

  test('updates the score for the given assignment', function () {
    this.stub(grade_summary, 'updateScoreForAssignment');
    this.onScoreChange('5');
    equal(grade_summary.updateScoreForAssignment.callCount, 1);
    const [assignmentId, score] = grade_summary.updateScoreForAssignment.getCall(0).args;
    equal(assignmentId, '201', 'the assignment id is 201');
    equal(score, 5, 'the parsed score is used to update the assignment score');
  });
});

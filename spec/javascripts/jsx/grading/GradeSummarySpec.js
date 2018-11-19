/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import _ from 'lodash'

import $ from 'jquery'
import I18n from 'i18n!gradebook'
import fakeENV from 'helpers/fakeENV'
import numberHelper from 'jsx/shared/helpers/numberHelper'
import CourseGradeCalculator from 'jsx/gradebook/CourseGradeCalculator'
import GradeSummary from 'jsx/grading/GradeSummary'
import {createCourseGradesWithGradingPeriods} from '../gradebook/GradeCalculatorSpecHelper'

const $fixtures = $('#fixtures')

let exampleGrades

function createAssignmentGroups() {
  return [
    {id: '301', assignments: [{id: '201', muted: false}, {id: '202', muted: true}]},
    {id: '302', assignments: [{id: '203', muted: true}]}
  ]
}

function createSubmissions() {
  return [{assignment_id: '201', score: 10}, {assignment_id: '203', score: 15}]
}

function createExampleGrades() {
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
  }
}

function createSubtotalsByAssignmentGroup() {
  ENV.assignment_groups = [{id: 1}, {id: 2}]
  ENV.grading_periods = []
  const calculatedGrades = {
    assignmentGroups: {
      1: {current: {score: 6, possible: 10}},
      2: {current: {score: 7, possible: 10}}
    }
  }
  const byGradingPeriod = false
  return GradeSummary.calculateSubtotals(byGradingPeriod, calculatedGrades, 'current')
}

function createSubtotalsByGradingPeriod() {
  ENV.assignment_groups = []
  ENV.grading_periods = [{id: 1}, {id: 2}]
  const calculatedGrades = {
    gradingPeriods: {
      1: {final: {score: 8, possible: 10}},
      2: {final: {score: 9, possible: 10}}
    }
  }
  const byGradingPeriod = true
  return GradeSummary.calculateSubtotals(byGradingPeriod, calculatedGrades, 'final')
}

function setPageHtmlFixture() {
  $fixtures.html(`
    <div id="grade_summary_fixture">
      <select class="grading_periods_selector">
        <option value="0" selected>All Grading Periods</option>
        <option value="701">Grading Period 1</option>
        <option value="702">Grading Period 2</option>
      </select>
      <div id="student-grades-right-content">
        <div class="student_assignment final_grade">
          <span class="grade"></span>
          <span class="final_letter_grade">
          (
            <span id="final_letter_grade_text" class="grade"></span>
          )
          </span>
          <span class="score_teaser"></span>
        </div>
        <div id="student-grades-whatif" class="show_guess_grades" style="display: none;">
          <button type="button" class="show_guess_grades_link">Show Saved "What-If" Scores</button>
        </div>
        <div id="student-grades-revert" class="revert_all_scores" style="display: none;">
          *NOTE*: This is NOT your official score.<br/>
          <button id="revert-all-to-actual-score" class="revert_all_scores_link">Revert to Actual Score</button>
        </div>
        <button id="show_all_details_button">Show All Details</button>
      </div>
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
              <span style="display: none;">
                <span class="original_points">10</span>
                <span class="original_score">10</span>
                <span class="what_if_score"></span>
                <span class="assignment_id">201</span>
                <span class="student_entered_score">7</span>
              </span>
            </div>
          </td>
        </tr>
      </table>
      <input type="text" id="grade_entry" style="display: none;" />
      <a id="revert_score_template" class="revert_score_link" >Revert Score</i></a>
      <a href="/assignments/{{ assignment_id }}" class="update_submission_url">&nbsp;</a>
    </div>
  `)
}

function commonSetup() {
  fakeENV.setup()
  $fixtures.html('')
}

function fullPageSetup() {
  fakeENV.setup()
  setPageHtmlFixture()
  ENV.submissions = createSubmissions()
  ENV.assignment_groups = createAssignmentGroups()
  ENV.group_weighting_scheme = 'points'
  GradeSummary.setup()
}

function commonTeardown() {
  fakeENV.teardown()
  $fixtures.html('')
}

QUnit.module('GradeSummary.getGradingPeriodSet', {
  setup() {
    commonSetup()
  },

  teardown() {
    commonTeardown()
  }
})

test('normalizes the grading period set from the env', function() {
  ENV.grading_period_set = {
    id: '1501',
    grading_periods: [{id: '701', weight: 50}, {id: '702', weight: 50}],
    weighted: true
  }
  const gradingPeriodSet = GradeSummary.getGradingPeriodSet()
  deepEqual(gradingPeriodSet.id, '1501')
  equal(gradingPeriodSet.gradingPeriods.length, 2)
  deepEqual(_.map(gradingPeriodSet.gradingPeriods, 'id'), ['701', '702'])
})

test('returns null when the grading period set is not defined in the env', function() {
  ENV.grading_period_set = undefined
  const gradingPeriodSet = GradeSummary.getGradingPeriodSet()
  deepEqual(gradingPeriodSet, null)
})

QUnit.module('GradeSummary.getAssignmentId', {
  setup() {
    commonSetup()
    setPageHtmlFixture()
  },

  teardown() {
    commonTeardown()
  }
})

test('returns the assignment id for the given .student_assignment element', function() {
  const $assignment = $fixtures.find('#grades_summary .student_assignment').first()
  strictEqual(GradeSummary.getAssignmentId($assignment), '201')
})

QUnit.module('GradeSummary.parseScoreText')

test('sets "numericalValue" to the parsed value', function() {
  const score = GradeSummary.parseScoreText('1,234')
  strictEqual(score.numericalValue, 1234)
})

test('sets "formattedValue" to the formatted value', function() {
  const score = GradeSummary.parseScoreText('1234')
  strictEqual(score.formattedValue, '1,234')
})

test('sets "numericalValue" to null when given an empty string', function() {
  const score = GradeSummary.parseScoreText('')
  strictEqual(score.numericalValue, null)
})

test('sets "numericalValue" to null when given null', function() {
  const score = GradeSummary.parseScoreText(null)
  strictEqual(score.numericalValue, null)
})

test('sets "numericalValue" to null when given undefined', function() {
  const score = GradeSummary.parseScoreText(undefined)
  strictEqual(score.numericalValue, null)
})

test('sets "numericalValue" to the "numericalDefault" when "numericalDefault" is a number', function() {
  const score = GradeSummary.parseScoreText(undefined, 5)
  strictEqual(score.numericalValue, 5)
})

test('sets "numericalValue" to null when "numericalDefault" is a string', function() {
  const score = GradeSummary.parseScoreText(undefined, '5')
  strictEqual(score.numericalValue, null)
})

test('sets "numericalValue" to null when "numericalDefault" is null', function() {
  const score = GradeSummary.parseScoreText(undefined, null)
  strictEqual(score.numericalValue, null)
})

test('sets "numericalValue" to null when "numericalDefault" is undefined', function() {
  const score = GradeSummary.parseScoreText(undefined, undefined)
  strictEqual(score.numericalValue, null)
})

test('sets "formattedValue" to "-" when given an empty string', function() {
  const score = GradeSummary.parseScoreText('')
  strictEqual(score.formattedValue, '-')
})

test('sets "formattedValue" to "-" when given null', function() {
  const score = GradeSummary.parseScoreText(null)
  strictEqual(score.formattedValue, '-')
})

test('sets "formattedValue" to "-" when given undefined', function() {
  const score = GradeSummary.parseScoreText(undefined)
  strictEqual(score.formattedValue, '-')
})

test('sets "formattedValue" to the "formattedDefault" when "formattedDefault" is a string', function() {
  const score = GradeSummary.parseScoreText(undefined, null, 'default')
  strictEqual(score.formattedValue, 'default')
})

test('sets "formattedValue" to "-" when "formattedDefault" is a number', function() {
  const score = GradeSummary.parseScoreText(undefined, null, 5)
  strictEqual(score.formattedValue, '-')
})

test('sets "formattedValue" to "-" when "formattedDefault" is null', function() {
  const score = GradeSummary.parseScoreText(undefined, null, null)
  strictEqual(score.formattedValue, '-')
})

test('sets "formattedValue" to "-" when "formattedDefault" is undefined', function() {
  const score = GradeSummary.parseScoreText(undefined, null, undefined)
  strictEqual(score.formattedValue, '-')
})

QUnit.module('GradeSummary.getOriginalScore', {
  setup() {
    fullPageSetup()
    this.$assignment = $fixtures.find('#grades_summary .student_assignment').first()
  },

  teardown() {
    commonTeardown()
  }
})

test('parses the text of the .original_points element', function() {
  const score = GradeSummary.getOriginalScore(this.$assignment)
  strictEqual(score.numericalValue, 10)
  strictEqual(score.formattedValue, '10')
})

test('sets "numericalValue" to a default of null', function() {
  this.$assignment.find('.original_points').text('invalid')
  const score = GradeSummary.getOriginalScore(this.$assignment)
  strictEqual(score.numericalValue, null)
})

test('sets "formattedValue" to formatted grade', function() {
  this.$assignment.find('.original_score').text('C+ (78.5)')
  const score = GradeSummary.getOriginalScore(this.$assignment)
  equal(score.formattedValue, 'C+ (78.5)')
})

QUnit.module('GradeSummary.calculateTotals', (suiteHooks) => {
  suiteHooks.beforeEach(() => {
    commonSetup()
    ENV.assignment_groups = createAssignmentGroups()
    sandbox.stub($, 'screenReaderFlashMessageExclusive')
    setPageHtmlFixture()
  })

  suiteHooks.afterEach(() => {
    commonTeardown()
  })

  test('displays a screenreader-only alert when grades have been changed', function() {
    $fixtures.find('.assignment_score .grade').addClass('changed')
    GradeSummary.calculateTotals(createExampleGrades(), 'current', 'percent')
    equal($.screenReaderFlashMessageExclusive.callCount, 1)
    const messageText = $.screenReaderFlashMessageExclusive.getCall(0).args[0]
    ok(messageText.includes('the new total is now'), 'flash message mentions new total')
  })

  test('does not display a screenreader-only alert when grades have not been changed', function() {
    GradeSummary.calculateTotals(createExampleGrades(), 'current', 'percent')
    equal($.screenReaderFlashMessageExclusive.callCount, 0)
  })

  test('localizes displayed grade', function() {
    sandbox.stub(I18n, 'n').returns('1,234')
    GradeSummary.calculateTotals(createExampleGrades(), 'current', 'percent')
    const $teaser = $fixtures.find('.student_assignment.final_grade .score_teaser')
    ok($teaser.text().includes('1,234'), 'includes internationalized score')
  })

  QUnit.module('final grade override', (contextHooks) => {
    contextHooks.beforeEach(() => {
      exampleGrades = createExampleGrades()
      ENV.grading_scheme = [['A', 0.90], ['B', 0.80], ['C', 0.70], ['D', 0.60], ['F', 0]]
    })

    test('sets the final letter grade to the effective final grade, if present', () => {
      ENV.effective_final_grade = 'D-'
      GradeSummary.calculateTotals(exampleGrades, 'current', 'percent')
      const $grade = $fixtures.find('.final_letter_grade .grade')
      strictEqual($grade.text(), 'D-')
    })

    test('sets the final letter grade to the calculated final grade, if not present', () => {
      GradeSummary.calculateTotals(exampleGrades, 'current', 'percent')
      const $grade = $fixtures.find('.final_letter_grade .grade')
      strictEqual($grade.text(), 'F')
    })

    test('sets the percent grade to the corresponding value of the effective grade, if present', () => {
      ENV.effective_final_grade = 'C'
      GradeSummary.calculateTotals(exampleGrades, 'current', 'percent')
      const $grade = $fixtures.find('.student_assignment.final_grade .grade').first()
      strictEqual($grade.text(), '70%')
    })

    test('changed What-If scores take precedence over the effective grade', () => {
      ENV.effective_final_grade = 'C'
      exampleGrades.current = {score: 3, possible: 10 }
      const changedGrade = '<span class="grade changed">3</span>'
      $fixtures.find('.score_holder .tooltip').html(changedGrade)
      GradeSummary.calculateTotals(exampleGrades, 'current', 'percent')
      const $grade = $fixtures.find('.student_assignment.final_grade .grade').first()
      strictEqual($grade.text(), '30%')
    })
  })
})


QUnit.module('GradeSummary.calculateSubtotalsByGradingPeriod', {
  setup() {
    this.subtotals = createSubtotalsByGradingPeriod()
  }
})

test('calculates subtotals by grading period', function() {
  equal(this.subtotals.length, 2, 'calculates a subtotal for each period')
})

test('creates teaser text for subtotals by grading period', function() {
  equal(this.subtotals[0].teaserText, '8.00 / 10.00', 'builds teaser text for first period')
  equal(this.subtotals[1].teaserText, '9.00 / 10.00', 'builds teaser text for second period')
})

test('creates grade text for subtotals by grading period', function() {
  equal(this.subtotals[0].gradeText, '80%', 'builds grade text for first period')
  equal(this.subtotals[1].gradeText, '90%', 'builds grade text for second period')
})

test('assigns row element ids for subtotals by grading period', function() {
  equal(
    this.subtotals[0].rowElementId,
    '#submission_period-1',
    'builds row element id for first period'
  )
  equal(
    this.subtotals[1].rowElementId,
    '#submission_period-2',
    'builds row element id for second period'
  )
})

QUnit.module('GradeSummary.calculateSubtotalsByAssignmentGroup', {
  setup() {
    this.subtotals = createSubtotalsByAssignmentGroup()
  }
})

test('calculates subtotals by assignment group', function() {
  equal(this.subtotals.length, 2, 'calculates a subtotal for each group')
})

test('calculates teaser text for subtotals by assignment group', function() {
  equal(this.subtotals[0].teaserText, '6.00 / 10.00', 'builds teaser text for first group')
  equal(this.subtotals[1].teaserText, '7.00 / 10.00', 'builds teaser text for second group')
})

test('calculates grade text for subtotals by assignment group', function() {
  equal(this.subtotals[0].gradeText, '60%', 'builds grade text for first group')
  equal(this.subtotals[1].gradeText, '70%', 'builds grade text for second group')
})

test('calculates row element ids for subtotals by assignment group', function() {
  equal(
    this.subtotals[0].rowElementId,
    '#submission_group-1',
    'builds row element id for first group'
  )
  equal(
    this.subtotals[1].rowElementId,
    '#submission_group-2',
    'builds row element id for second group'
  )
})

QUnit.module('GradeSummary.canBeConvertedToGrade')

test('returns false when possible is nonpositive', function() {
  notOk(GradeSummary.canBeConvertedToGrade(1, 0))
})

test('returns false when score is NaN', function() {
  notOk(GradeSummary.canBeConvertedToGrade(NaN, 1))
})

test('returns true when score is a number and possible is positive', function() {
  ok(GradeSummary.canBeConvertedToGrade(1, 1))
})

QUnit.module('GradeSummary.calculatePercentGrade')

test('returns properly computed and rounded value', function() {
  const percentGrade = GradeSummary.calculatePercentGrade(1, 3)
  strictEqual(percentGrade, 33.33)
})

test('avoids floating point calculation issues', function() {
  const percentGrade = GradeSummary.calculatePercentGrade(946.65, 1000)
  strictEqual(percentGrade, 94.67)
})

QUnit.module('GradeSummary.formatPercentGrade')

test('returns an internationalized number value', function() {
  sandbox
    .stub(I18n, 'n')
    .withArgs(1234)
    .returns('1,234%')
  equal(GradeSummary.formatPercentGrade(1234), '1,234%')
})

QUnit.module('GradeSummary.calculateGrade')

test('returns an internationalized percentage when given a score and nonzero points possible', function() {
  sandbox.stub(I18n, 'n').callsFake(number => `${number}%`)
  equal(GradeSummary.calculateGrade(97, 100), '97%')
  equal(I18n.n.getCall(0).args[1].percentage, true)
})

test('returns "N/A" when given a numerical score and zero points possible', function() {
  equal(GradeSummary.calculateGrade(1, 0), 'N/A')
})

test('returns "N/A" when given a non-numerical score and nonzero points possible', function() {
  equal(GradeSummary.calculateGrade(undefined, 1), 'N/A')
})

QUnit.module('GradeSummary.calculateGrades', {
  setup() {
    commonSetup()
    ENV.submissions = createSubmissions()
    ENV.assignment_groups = createAssignmentGroups()
    ENV.group_weighting_scheme = 'points'
    ENV.grading_period_set = {
      id: '1501',
      grading_periods: [{id: '701', weight: 50}, {id: '702', weight: 50}],
      weighted: true
    }
    ENV.effective_due_dates = {201: {101: {grading_period_id: '701'}}}
    ENV.student_id = '101'
    exampleGrades = createCourseGradesWithGradingPeriods()
    sandbox.stub(CourseGradeCalculator, 'calculate').returns(exampleGrades)
  },

  teardown() {
    commonTeardown()
  }
})

test('calculates grades using data in the env', function() {
  GradeSummary.calculateGrades()
  const args = CourseGradeCalculator.calculate.getCall(0).args
  equal(args[0], ENV.submissions)
  deepEqual(_.map(args[1], 'id'), ['301', '302'])
  equal(args[2], ENV.group_weighting_scheme)
})

test('normalizes the grading period set before calculation', function() {
  GradeSummary.calculateGrades()
  const gradingPeriodSet = CourseGradeCalculator.calculate.getCall(0).args[3]
  deepEqual(gradingPeriodSet.id, '1501')
  equal(gradingPeriodSet.gradingPeriods.length, 2)
  deepEqual(_.map(gradingPeriodSet.gradingPeriods, 'id'), ['701', '702'])
})

test('scopes effective due dates to the user', function() {
  GradeSummary.calculateGrades()
  const dueDates = CourseGradeCalculator.calculate.getCall(0).args[4]
  deepEqual(dueDates, {201: {grading_period_id: '701'}})
})

test('calculates grades without grading period data when the grading period set is not defined', function() {
  delete ENV.grading_period_set
  GradeSummary.calculateGrades()
  const args = CourseGradeCalculator.calculate.getCall(0).args
  equal(args[0], ENV.submissions)
  equal(args[1], ENV.assignment_groups)
  equal(args[2], ENV.group_weighting_scheme)
  equal(typeof args[3], 'undefined')
  equal(typeof args[4], 'undefined')
})

test('calculates grades without grading period data when effective due dates are not defined', function() {
  delete ENV.effective_due_dates
  GradeSummary.calculateGrades()
  const args = CourseGradeCalculator.calculate.getCall(0).args
  equal(args[0], ENV.submissions)
  equal(args[1], ENV.assignment_groups)
  equal(args[2], ENV.group_weighting_scheme)
  equal(typeof args[3], 'undefined')
  equal(typeof args[4], 'undefined')
})

test('returns course grades when no grading period id is provided', function() {
  sandbox.stub(GradeSummary, 'getSelectedGradingPeriodId').returns(null)
  const grades = GradeSummary.calculateGrades()
  equal(grades, exampleGrades)
})

test('scopes grades to the provided grading period id', function() {
  sandbox.stub(GradeSummary, 'getSelectedGradingPeriodId').returns('701')
  const grades = GradeSummary.calculateGrades()
  equal(grades, exampleGrades.gradingPeriods[701])
})

QUnit.module('GradeSummary.setup', {
  setup() {
    fakeENV.setup()
    setPageHtmlFixture()
    ENV.submissions = createSubmissions()
    ENV.assignment_groups = createAssignmentGroups()
    ENV.group_weighting_scheme = 'points'
    this.$showWhatIfScoresContainer = $fixtures.find('#student-grades-whatif')
    this.$assignment = $fixtures.find('#grades_summary .student_assignment').first()
  },

  teardown() {
    commonTeardown()
  }
})

test('shows the "Show Saved What-If Scores" button when any assignment has a What-If score', function() {
  GradeSummary.setup()
  ok(this.$showWhatIfScoresContainer.is(':visible'), 'button container is visible')
})

test('uses I18n to parse the .student_entered_score value', function() {
  sandbox.spy(GradeSummary, 'parseScoreText')
  this.$assignment.find('.student_entered_score').text('7')
  GradeSummary.setup()
  equal(GradeSummary.parseScoreText.callCount, 1, 'GradeSummary.parseScoreText was called once')
  const [value] = GradeSummary.parseScoreText.getCall(0).args
  equal(value, '7', 'GradeSummary.parseScoreText was called with the .student_entered_score')
})

test('shows the "Show Saved What-If Scores" button for assignments with What-If scores of "0"', function() {
  this.$assignment.find('.student_entered_score').text('0')
  GradeSummary.setup()
  ok(this.$showWhatIfScoresContainer.is(':visible'), 'button container is visible')
})

test('does not show the "Show Saved What-If Scores" button for assignments without What-If scores', function() {
  this.$assignment.find('.student_entered_score').text('')
  GradeSummary.setup()
  ok(this.$showWhatIfScoresContainer.is(':hidden'), 'button container is hidden')
})

test('does not show the "Show Saved What-If Scores" button for assignments with What-If invalid scores', function() {
  this.$assignment.find('.student_entered_score').text('null')
  GradeSummary.setup()
  ok(this.$showWhatIfScoresContainer.is(':hidden'), 'button container is hidden')
})

QUnit.module('Grade Summary "Show Saved What-If Scores" button', {
  setup() {
    fakeENV.setup()
    setPageHtmlFixture()
    ENV.submissions = createSubmissions()
    ENV.assignment_groups = createAssignmentGroups()
    ENV.group_weighting_scheme = 'points'
    GradeSummary.setup()
    this.$showWhatIfScoresButton = $fixtures.find('.show_guess_grades_link')
    this.$assignment = $fixtures.find('#grades_summary .student_assignment').first()
  },

  teardown() {
    commonTeardown()
  }
})

test('reveals all What-If scores when clicked', function() {
  this.$showWhatIfScoresButton.click()
  equal(
    this.$assignment.find('.what_if_score').text(),
    '7',
    'what_if_score is set to the .student_entered_score'
  )
})

test('hides the assignment .score_value element', function() {
  this.$showWhatIfScoresButton.click()
  const $scoreValue = $fixtures.find('.assignment_score .score_value').first()
  ok($scoreValue.is(':hidden'), '.score_value is hidden')
})

test('triggers onScoreChange for the assignment', function() {
  sandbox.stub(GradeSummary, 'onScoreChange')
  this.$showWhatIfScoresButton.click()
  equal(
    GradeSummary.onScoreChange.callCount,
    1,
    'called once for each assignment (only one in fixture)'
  )
  const [$assignment, options] = GradeSummary.onScoreChange.getCall(0).args
  equal(
    $assignment.get(0),
    this.$assignment.get(0),
    'first parameter is the assignment jquery object'
  )
  deepEqual(
    options,
    {update: false, refocus: false},
    'second parameter is the assignment jquery object'
  )
})

test('uses I18n to parse the .student_entered_score value', function() {
  sandbox.stub(GradeSummary, 'onScoreChange')
  sandbox.spy(GradeSummary, 'parseScoreText')
  this.$assignment.find('.student_entered_score').text('7')
  this.$showWhatIfScoresButton.click()
  equal(GradeSummary.parseScoreText.callCount, 1, 'GradeSummary.parseScoreText was called once')
  const [value] = GradeSummary.parseScoreText.getCall(0).args
  equal(value, '7', 'GradeSummary.parseScoreText was called with the .student_entered_score')
})

test('includes assignments with What-If scores of "0"', function() {
  this.$assignment.find('.student_entered_score').text('0')
  this.$showWhatIfScoresButton.click()
  equal(
    this.$assignment.find('.what_if_score').text(),
    '0',
    'what_if_score is set to the .student_entered_score'
  )
})

test('ignores assignments without What-If scores', function() {
  sandbox.stub(GradeSummary, 'onScoreChange')
  this.$assignment.find('.student_entered_score').text('')
  this.$showWhatIfScoresButton.click()
  const $scoreValue = $fixtures.find('.assignment_score .score_value').first()
  notOk($scoreValue.is(':hidden'), '.score_value is not hidden')
  equal(GradeSummary.onScoreChange.callCount, 0, 'onScoreChange is not called')
  equal(this.$assignment.find('.what_if_score').text(), '', 'what_if_score is not changed')
})

test('ignores assignments with invalid What-If score text', function() {
  sandbox.stub(GradeSummary, 'onScoreChange')
  this.$assignment.find('.student_entered_score').text('null')
  this.$showWhatIfScoresButton.click()
  const $scoreValue = $fixtures.find('.assignment_score .score_value').first()
  notOk($scoreValue.is(':hidden'), '.score_value is not hidden')
  equal(GradeSummary.onScoreChange.callCount, 0, 'onScoreChange is not called')
  equal(this.$assignment.find('.what_if_score').text(), '', 'what_if_score is not changed')
})

test('hides itself when clicked', function() {
  this.$showWhatIfScoresButton.click()
  ok(this.$showWhatIfScoresButton.is(':hidden'), 'button is hidden')
})

test('sets focus on the "revert all scores" button', function() {
  this.$showWhatIfScoresButton.click()
  equal(document.activeElement, $('#revert-all-to-actual-score').get(0), 'button is active element')
})

test('displays a screenreader message indicating visibility of What-If scores', function() {
  sandbox.stub(GradeSummary, 'onScoreChange')
  sandbox.stub($, 'screenReaderFlashMessageExclusive')
  this.$showWhatIfScoresButton.click()
  equal(
    $.screenReaderFlashMessageExclusive.callCount,
    1,
    'screenReaderFlashMessageExclusive is called once'
  )
  const [message] = $.screenReaderFlashMessageExclusive.getCall(0).args
  equal(message, 'Grades are now showing what-if scores')
})

QUnit.module('Grade Summary "Show All Details" button', {
  setup() {
    fakeENV.setup()
    setPageHtmlFixture()
    ENV.submissions = createSubmissions()
    ENV.assignment_groups = createAssignmentGroups()
    ENV.group_weighting_scheme = 'points'
    GradeSummary.setup()
  },

  teardown() {
    commonTeardown()
  }
})

test('announces "assignment details expanded" when clicked', function() {
  $('#show_all_details_button').click()
  equal($('#aria-announcer').text(), 'assignment details expanded')
})

test('changes text to "Hide All Details" when clicked', function() {
  $('#show_all_details_button').click()
  equal($('#show_all_details_button').text(), 'Hide All Details')
})

test('announces "assignment details collapsed" when clicked and already expanded', function() {
  $('#show_all_details_button').click()
  $('#show_all_details_button').click()
  equal($('#aria-announcer').text(), 'assignment details collapsed')
})

test('changes text to "Show All Details" when clicked twice', function() {
  $('#show_all_details_button').click()
  $('#show_all_details_button').click()
  equal($('#show_all_details_button').text(), 'Show All Details')
})

QUnit.module('GradeSummary.onEditWhatIfScore', {
  setup() {
    fullPageSetup()
    $fixtures
      .find('.assignment_score .grade')
      .first()
      .append('5')
  },

  onEditWhatIfScore() {
    const $assignmentScore = $fixtures.find('.assignment_score').first()
    GradeSummary.onEditWhatIfScore($assignmentScore, $('#aria-announcer'))
  },

  teardown() {
    commonTeardown()
  }
})

test('stores the original score when editing the the first time', function() {
  const $grade = $fixtures.find('.assignment_score .grade').first()
  const expectedHtml = $grade.html()
  this.onEditWhatIfScore()
  equal($grade.data('originalValue'), expectedHtml)
})

test('does not store the score when the original score is already stored', function() {
  const $grade = $fixtures.find('.assignment_score .grade').first()
  $grade.data('originalValue', '10')
  this.onEditWhatIfScore()
  equal($grade.data('originalValue'), '10')
})

test('attaches a screenreader-only element to the grade element as data', function() {
  this.onEditWhatIfScore()
  const $grade = $fixtures.find('.assignment_score .grade').first()
  ok($grade.data('screenreader_link'), '"screenreader_link" is assigned as data')
  ok(
    $grade.data('screenreader_link').hasClass('screenreader-only'),
    '"screenreader_link" is screenreader-only'
  )
})

test('hides the score value', function() {
  this.onEditWhatIfScore()
  const $scoreValue = $fixtures.find('.assignment_score .score_value').first()
  ok($scoreValue.is(':hidden'), '.score_value is hidden')
})

test('replaces the grade element content with a grade entry field', function() {
  this.onEditWhatIfScore()
  const $gradeEntry = $fixtures.find('.assignment_score .grade > #grade_entry')
  equal($gradeEntry.length, 1, '#grade_entry is attached to the .grade element')
})

test('sets the value of the grade entry to the existing "What-If" score', function() {
  $fixtures
    .find('.assignment_score')
    .first()
    .find('.what_if_score')
    .text('15')
  this.onEditWhatIfScore()
  const $gradeEntry = $fixtures.find('#grade_entry').first()
  equal($gradeEntry.val(), '15', 'the previous "What-If" score is 15')
})

test('defaults the value of the grade entry to "0" when no score is present', function() {
  this.onEditWhatIfScore()
  const $gradeEntry = $fixtures.find('#grade_entry').first()
  equal($gradeEntry.val(), '0', 'there is no previous "What-If" score')
})

test('uses I18n to parse the existing "What-If" score', function() {
  $fixtures
    .find('.assignment_score')
    .first()
    .find('.what_if_score')
    .text('1.234,56')
  sandbox
    .stub(numberHelper, 'parse')
    .withArgs('1.234,56')
    .returns('654321')
  this.onEditWhatIfScore()
  const $gradeEntry = $fixtures.find('#grade_entry').first()
  equal(
    $gradeEntry.val(),
    '654321',
    'the previous "What-If" score might have been internationalized'
  )
})

test('shows the grade entry', function() {
  this.onEditWhatIfScore()
  const $gradeEntry = $fixtures.find('#grade_entry').first()
  ok($gradeEntry.is(':visible'), '#grade_entry does not have "visibility: none"')
})

test('sets focus on the grade entry', function() {
  this.onEditWhatIfScore()
  const $gradeEntry = $fixtures.find('#grade_entry').first()
  equal($gradeEntry.get(0), document.activeElement, '#grade_entry is the active element')
})

test('selects the grade entry', function() {
  this.onEditWhatIfScore()
  const $gradeEntry = $fixtures.find('#grade_entry').get(0)
  equal($gradeEntry.selectionStart, 0, 'selection starts at beginning of score text')
  equal($gradeEntry.selectionEnd, 1, 'selection ends at end of score text')
})

test('announces message for entering a "What-If" score', function() {
  this.onEditWhatIfScore()
  equal($('#aria-announcer').text(), 'Enter a What-If score.')
})

QUnit.module('GradeSummary.onScoreChange', {
  setup() {
    fullPageSetup()
    sandbox.stub($, 'ajaxJSON')
    this.$assignment = $fixtures.find('#grades_summary .student_assignment').first()
    // reproduce the destructive part of .onEditWhatIfScore
    this.$assignment
      .find('.assignment_score')
      .find('.grade')
      .empty()
      .append($('#grade_entry'))
  },

  onScoreChange(score, options = {}) {
    this.$assignment.find('#grade_entry').val(score)
    GradeSummary.onScoreChange(this.$assignment, {update: false, refocus: false, ...options})
  },

  teardown() {
    commonTeardown()
  }
})

test('updates .what_if_score with the parsed value from #grade_entry', function() {
  this.onScoreChange('5')
  equal(this.$assignment.find('.what_if_score').text(), '5')
})

test('uses I18n to parse the #grade_entry score', function() {
  sandbox
    .stub(numberHelper, 'parse')
    .withArgs('1.234,56')
    .returns('654321')
  this.onScoreChange('1.234,56')
  equal(this.$assignment.find('.what_if_score').text(), '654321')
})

test('uses the previous .what_if_score value when #grade_entry is blank', function() {
  this.$assignment.find('.what_if_score').text('9.0')
  this.onScoreChange('')
  equal(this.$assignment.find('.what_if_score').text(), '9')
})

test('uses I18n to parse the previous .what_if_score value', function() {
  sandbox
    .stub(numberHelper, 'parse')
    .withArgs('9.0')
    .returns('654321')
  this.$assignment.find('.what_if_score').text('9.0')
  this.onScoreChange('')
  equal(this.$assignment.find('.what_if_score').text(), '654321')
})

test('removes the .dont_update class from the .student_assignment element when present', function() {
  this.$assignment.addClass('dont_update')
  this.onScoreChange('5')
  notOk(this.$assignment.hasClass('dont_update'))
})

test('saves the "What-If" grade using the api', function() {
  this.onScoreChange('5', {update: true})
  equal($.ajaxJSON.callCount, 1, '$.ajaxJSON was called once')
  const [url, method, params] = $.ajaxJSON.getCall(0).args
  equal(url, '/assignments/201', 'constructs the url from elements in the DOM')
  equal(method, 'PUT', 'uses PUT for updates')
  equal(params['submission[student_entered_score]'], 5)
})

test('updates the .student_entered_score element upon success api update', function() {
  $.ajaxJSON.callsFake((_url, _method, args, onSuccess) => {
    onSuccess({submission: {student_entered_score: args['submission[student_entered_score]']}})
  })
  this.onScoreChange('5', {update: true})
  equal(this.$assignment.find('.student_entered_score').text(), '5')
})

test('does not save the "What-If" grade when .dont_update class is present', function() {
  this.$assignment.addClass('dont_update')
  this.onScoreChange('5', {update: true})
  equal($.ajaxJSON.callCount, 0, '$.ajaxJSON was not called')
})

test('does not save the "What-If" grade when the "update" option is false', function() {
  this.onScoreChange('5', {update: false})
  equal($.ajaxJSON.callCount, 0, '$.ajaxJSON was not called')
})

test('hides the #grade_entry input', function() {
  this.onScoreChange('5')
  ok($('#grade_entry').is(':hidden'))
})

test('moves the #grade_entry to the body', function() {
  this.onScoreChange('5')
  ok(
    $('#grade_entry')
      .parent()
      .is('body')
  )
})

test('sets the .assignment_score title to ""', function() {
  this.onScoreChange('5')
  equal(this.$assignment.find('.assignment_score').attr('title'), '')
})

test('sets the .assignment_score teaser text', function() {
  this.onScoreChange('5')
  equal(this.$assignment.find('.score_teaser').text(), 'This is a What-If score')
})

test('copies the "revert score" link into the .score_holder element', function() {
  this.onScoreChange('5')
  equal(
    this.$assignment.find('.score_holder .revert_score_link').length,
    1,
    'includes a "revert score" link'
  )
  equal(this.$assignment.find('.score_holder .revert_score_link').text(), 'Revert Score')
})

test('adds the "changed" class to the .grade element', function() {
  this.onScoreChange('5')
  ok(this.$assignment.find('.grade').hasClass('changed'))
})

test('sets the .grade element content to the updated score', function() {
  this.onScoreChange('5')
  equal(this.$assignment.find('.grade').html(), '5')
})

test('sets the .grade element content to the previous score when the updated score is falsy', function() {
  this.$assignment.find('.grade').data('originalValue', '10.0')
  this.onScoreChange('')
  equal(this.$assignment.find('.grade').html(), '10')
})

test('updates the score for the given assignment', function() {
  sandbox.stub(GradeSummary, 'updateScoreForAssignment')
  this.onScoreChange('5')
  equal(GradeSummary.updateScoreForAssignment.callCount, 1)
  const [assignmentId, score] = GradeSummary.updateScoreForAssignment.getCall(0).args
  equal(assignmentId, '201', 'the assignment id is 201')
  equal(score, 5, 'the parsed score is used to update the assignment score')
})

QUnit.module('GradeSummary - Revert Score', {
  setup() {
    fullPageSetup()
    this.$assignment = $fixtures.find('#grades_summary .student_assignment').first()
    const $assignmentScore = this.$assignment.find('.assignment_score')
    // reproduce the What-If setup from .onEditWhatIfScore
    const $screenreaderLinkClone = $assignmentScore.find('.screenreader-only').clone(true)
    $assignmentScore.find('.grade').data('screenreader_link', $screenreaderLinkClone)
    // reproduce the What-If setup from .onScoreChange
    const $scoreTeaser = $assignmentScore.find('.score_teaser')
    const $grade = this.$assignment.find('.grade')
    $assignmentScore.attr('title', '')
    $scoreTeaser.text('This is a What-If score')
    const $revertScore = $('#revert_score_template')
      .clone(true)
      .attr('id', '')
      .show()
    $assignmentScore.find('.score_holder').append($revertScore)
    $grade.addClass('changed')
    this.$assignment.find('.original_score').text('5')
  },

  onScoreRevert() {
    GradeSummary.onScoreRevert(this.$assignment, {refocus: false, skipEval: false})
  },

  teardown() {
    commonTeardown()
  }
})

test('sets the .what_if_score text to the .original_score text', function() {
  this.onScoreRevert()
  equal(this.$assignment.find('.what_if_score').text(), '5')
})

test('sets the .assignment_score title to the "Click to test" message', function() {
  this.onScoreRevert()
  equal(this.$assignment.find('.assignment_score').attr('title'), 'Click to test a different score')
})

test('sets the .score_teaser text to the "Click to test" message when the assignment is not muted', function() {
  this.onScoreRevert()
  equal(this.$assignment.find('.score_teaser').text(), 'Click to test a different score')
})

test('sets the .score_teaser text to the "Instructor is working" message when the assignment is muted', function() {
  this.$assignment.data('muted', true)
  this.onScoreRevert()
  equal(this.$assignment.find('.score_teaser').text(), 'Instructor is working on grades')
})

test('removes the "changed" class from the .grade element', function() {
  this.onScoreRevert()
  notOk(
    this.$assignment.find('.assignment_score .grade').hasClass('changed'),
    'changed class is not present'
  )
})

test('removes the .revert_score_link element', function() {
  this.onScoreRevert()
  equal(this.$assignment.find('.revert_score_link').length, 0)
})

test('sets the .score_value text to the .original_score text', function() {
  this.onScoreRevert()
  equal(this.$assignment.find('.score_value').text(), '5')
})

test('sets the .grade html to the "muted assignment" indicator when the assignment is muted', function() {
  this.$assignment.data('muted', true)
  this.onScoreRevert()
  equal(this.$assignment.find('.grade .muted_icon').length, 1)
})

test('sets the .grade text to .original_score when the assignment is not muted', function() {
  this.onScoreRevert()
  const $grade = this.$assignment.find('.grade')
  $grade.children().remove() // remove all content except score text
  equal($grade.text(), '5')
})

test('updates the score for the assignment', function() {
  sandbox.stub(GradeSummary, 'updateScoreForAssignment')
  this.onScoreRevert()
  equal(GradeSummary.updateScoreForAssignment.callCount, 1)
  const [assignmentId, score] = GradeSummary.updateScoreForAssignment.getCall(0).args
  equal(assignmentId, '201', 'first argument is the assignment id 201')
  strictEqual(score, 10, 'second argument is the numerical score 10')
})

test('updates the score for the assignment with null when the .original_points is blank', function() {
  this.$assignment.find('.original_points').text('')
  sandbox.stub(GradeSummary, 'updateScoreForAssignment')
  this.onScoreRevert()
  const score = GradeSummary.updateScoreForAssignment.getCall(0).args[1]
  strictEqual(score, null)
})

test('updates the student grades after updating the assignment score', function() {
  sandbox.stub(GradeSummary, 'updateScoreForAssignment')
  sandbox.stub(GradeSummary, 'updateStudentGrades').callsFake(() => {
    equal(
      GradeSummary.updateScoreForAssignment.callCount,
      1,
      'updateScoreForAssignment is performed first'
    )
  })
  this.onScoreRevert()
  equal(GradeSummary.updateStudentGrades.callCount, 1, 'updateStudentGrades is called once')
})

test('attaches a "Click to test" .screenreader-only element to the grade element', function() {
  const $grade = $fixtures.find('.assignment_score .grade').first()
  this.onScoreRevert()
  equal($grade.find('.screenreader-only').length, 1)
  equal($grade.find('.screenreader-only').text(), 'Click to test a different score')
})

QUnit.module('GradeSummary.updateScoreForAssignment', {
  setup() {
    fakeENV.setup()
    ENV.submissions = createSubmissions()
  },

  teardown() {
    fakeENV.teardown()
  }
})

test('updates the score for an existing submission', function() {
  GradeSummary.updateScoreForAssignment('203', 20)
  equal(ENV.submissions[1].score, 20, 'the second submission is for assignment 203')
})

test('ignores submissions not having the given assignment id', function() {
  GradeSummary.updateScoreForAssignment('203', 20)
  equal(ENV.submissions[0].score, 10, 'the first submission is for assignment 201')
})

test('adds a submission with the score when no submission matches the given assignment id', function() {
  GradeSummary.updateScoreForAssignment('205', 30)
  equal(ENV.submissions.length, 3, 'submission count has changed from 2 to 3')
  deepEqual(_.map(ENV.submissions, 'assignment_id'), ['201', '203', '205'])
  deepEqual(_.map(ENV.submissions, 'score'), [10, 15, 30])
})

QUnit.module('GradeSummary.finalGradePointsPossibleText', {
  setup() {
    fakeENV.setup()
  },

  teardown() {
    fakeENV.teardown()
  }
})

test('returns an empty string if assignment groups are weighted', function() {
  const text = GradeSummary.finalGradePointsPossibleText('percent', '50.00 / 100.00')
  strictEqual(text, '')
})

test('returns the score with points possible if assignment groups are not weighted', function() {
  const text = GradeSummary.finalGradePointsPossibleText('equal', '50.00 / 100.00')
  strictEqual(text, '50.00 / 100.00')
})

test('returns an empty string if grading periods are weighted and "All Grading Periods" is selected', function() {
  ENV.grading_period_set = {
    id: '1501',
    grading_periods: [{id: '701', weight: 50}, {id: '702', weight: 50}],
    weighted: true
  }
  ENV.current_grading_period_id = '0'
  const text = GradeSummary.finalGradePointsPossibleText('equal', '50.00 / 100.00')
  strictEqual(text, '')
})

test('returns the score with points possible if grading periods are weighted and a period is selected', function() {
  ENV.grading_period_set = {
    id: '1501',
    grading_periods: [{id: '701', weight: 50}, {id: '702', weight: 50}],
    weighted: true
  }
  ENV.current_grading_period_id = '701'
  const text = GradeSummary.finalGradePointsPossibleText('equal', '50.00 / 100.00')
  strictEqual(text, '50.00 / 100.00')
})

test('returns the score with points possible if grading periods are not weighted', function() {
  ENV.grading_period_set = {
    id: '1501',
    grading_periods: [{id: '701', weight: 50}, {id: '702', weight: 50}],
    weighted: false
  }

  const text = GradeSummary.finalGradePointsPossibleText('equal', '50.00 / 100.00')
  strictEqual(text, '50.00 / 100.00')
})

QUnit.module('GradeSummary', () => {
  QUnit.module('.getSelectedGradingPeriodId', hooks => {
    hooks.beforeEach(() => {
      fakeENV.setup()
    })

    hooks.afterEach(() => {
      fakeENV.teardown()
    })

    test('returns the id of the current grading period', () => {
      ENV.current_grading_period_id = '701'

      strictEqual(GradeSummary.getSelectedGradingPeriodId(), '701')
    })

    test('returns null when the current grading period is "All Grading Periods"', () => {
      ENV.current_grading_period_id = '0'

      strictEqual(GradeSummary.getSelectedGradingPeriodId(), null)
    })

    test('returns null when there is no current grading period', () => {
      strictEqual(GradeSummary.getSelectedGradingPeriodId(), null)
    })
  })

  QUnit.module('#renderSelectMenuGroup', hooks => {
    const props = {
      assignmentSortOptions: [],
      courses: [],
      currentUserID: '42',
      displayPageContent() {},
      goToURL() {},
      gradingPeriods: [],
      saveAssignmentOrder() {},
      selectedAssignmentSortOrder: '1',
      selectedCourseID: '2',
      selectedGradingPeriodID: '3',
      selectedStudentID: '4',
      students: []
    }

    hooks.beforeEach(() => {
      sinon.stub(GradeSummary, 'getSelectMenuGroupProps').returns(props)
      fakeENV.setup({context_asset_string: 'course_42', current_user: {}})
    })

    hooks.afterEach(() => {
      fakeENV.teardown()
      GradeSummary.getSelectMenuGroupProps.restore()
    })

    test('calls getSelectMenuGroupProps', () => {
      $('#fixtures').html('<div id="GradeSummarySelectMenuGroup"></div>')
      GradeSummary.renderSelectMenuGroup()

      strictEqual(GradeSummary.getSelectMenuGroupProps.callCount, 1)
    })
  })

  QUnit.module('#getSelectMenuGroupProps', hooks => {
    hooks.beforeEach(() => {
      fakeENV.setup({
        context_asset_string: 'course_42',
        current_user: {},
        courses_with_grades: []
      })
    })

    hooks.afterEach(() => {
      fakeENV.teardown()
    })

    test('sets assignmentSortOptions to the assignment_sort_options environment variable', () => {
      ENV.assignment_sort_options = [
        ['Assignment Group', 'assignment_group'],
        ['Due Date', 'due_at'],
        ['Title', 'title']
      ]

      deepEqual(
        GradeSummary.getSelectMenuGroupProps().assignmentSortOptions,
        ENV.assignment_sort_options
      )
    })

    test('sets courses to camelized version of courses_with_grades', () => {
      ENV.courses_with_grades = [
        {grading_period_set: null, id: '15', nickname: 'Course #1', url: '/courses/15/grades'},
        {grading_period_set: 3, id: '42', nickname: 'Course #2', url: '/courses/42/grades'}
      ]

      const expectedCourses = [
        {gradingPeriodSet: null, id: '15', nickname: 'Course #1', url: '/courses/15/grades'},
        {gradingPeriodSet: 3, id: '42', nickname: 'Course #2', url: '/courses/42/grades'}
      ]

      deepEqual(GradeSummary.getSelectMenuGroupProps().courses, expectedCourses)
    })

    test('sets currentUserID to the current user id as set in the environment', () => {
      ENV.current_user = {id: 42}

      strictEqual(GradeSummary.getSelectMenuGroupProps().currentUserID, 42)
    })

    test('sets gradingPeriods to the grading period data passed in the environment', () => {
      ENV.grading_periods = [
        {
          id: '6',
          close_date: '2017-09-01T05:59:59Z',
          end_date: '2017-09-01T05:59:59Z',
          is_closed: true,
          is_last: false,
          permissions: {
            create: false,
            delete: false,
            read: true,
            update: false
          },
          start_date: '2017-08-01T06:00:00Z',
          title: 'Summer 2017',
          weight: 10
        }
      ]

      deepEqual(GradeSummary.getSelectMenuGroupProps().gradingPeriods, ENV.grading_periods)
    })

    test('sets gradingPeriods to an empty array if there is no grading period data in the environment', () => {
      deepEqual(GradeSummary.getSelectMenuGroupProps().gradingPeriods, [])
    })

    test('sets selectedAssignmentSortOrder to the current_assignment_sort_order environment variable', () => {
      ENV.current_assignment_sort_order = 'due_at'

      strictEqual(
        GradeSummary.getSelectMenuGroupProps().selectedAssignmentSortOrder,
        ENV.current_assignment_sort_order
      )
    })

    test('sets selectedCourseID to the context id', () => {
      strictEqual(GradeSummary.getSelectMenuGroupProps().selectedCourseID, '42')
    })

    test('sets selectedGradingPeriodID to the current_grading_period_id environment variable', () => {
      ENV.current_grading_period_id = '3'

      strictEqual(
        GradeSummary.getSelectMenuGroupProps().selectedGradingPeriodID,
        ENV.current_grading_period_id
      )
    })

    test('sets selectedStudentID to the student_id environment variable', () => {
      ENV.student_id = '66'

      strictEqual(GradeSummary.getSelectMenuGroupProps().selectedStudentID, ENV.student_id)
    })

    test('sets students to the students environment variable', () => {
      ENV.students = [{id: 42, name: 'Abel'}, {id: 43, name: 'Baker'}]

      deepEqual(GradeSummary.getSelectMenuGroupProps().students, ENV.students)
    })
  })
})

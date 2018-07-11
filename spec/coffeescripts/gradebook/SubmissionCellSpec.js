/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import SubmissionCell from 'compiled/gradebook/SubmissionCell'
import htmlEscape from 'str/htmlEscape'
import $ from 'jquery'
import numberHelper from 'jsx/shared/helpers/numberHelper'

const dangerousHTML = '"><img src=/ onerror=alert(document.cookie);>'
const escapedDangerousHTML = htmlEscape(dangerousHTML)

QUnit.module('SubmissionCell', {
  setup() {
    this.pointsPossible = 100
    this.opts = {
      item: {whatever: {}},
      column: {
        field: 'whatever',
        object: {points_possible: this.pointsPossible}
      },
      container: $('#fixtures')[0]
    }
    this.cell = new SubmissionCell(this.opts)
  },
  teardown() {
    $('#fixtures').empty()
  }
})

test('#applyValue escapes html in passed state', function() {
  const item = {whatever: {grade: '1'}}
  const state = dangerousHTML
  sandbox.stub(this.cell, 'postValue')
  this.cell.applyValue(item, state)
  equal(item.whatever.grade, escapedDangerousHTML)
})

test('#applyValue calls flashWarning', function() {
  sandbox.stub(this.cell, 'postValue')
  const flashWarningStub = sandbox.stub($, 'flashWarning')
  this.cell.applyValue(this.opts.item, '150')
  ok(flashWarningStub.calledOnce)
})

test('#applyValue calls numberHelper with points possible', function() {
  const numberHelperStub = sandbox.stub(numberHelper, 'parse').withArgs(this.pointsPossible)
  sandbox.stub(this.cell, 'postValue')
  this.cell.applyValue(this.opts.item, '10')
  strictEqual(numberHelperStub.callCount, 1)
})

test('#applyValue calls numberHelper with state', function() {
  const state = '10'
  const numberHelperStub = sandbox.stub(numberHelper, 'parse').withArgs(state)
  sandbox.stub(this.cell, 'postValue')
  this.cell.applyValue(this.opts.item, state)
  strictEqual(numberHelperStub.callCount, 1)
})

test('#loadValue escapes html', function() {
  this.opts.item.whatever.grade = dangerousHTML
  this.cell.loadValue()
  equal(this.cell.$input.val(), escapedDangerousHTML)
  equal(this.cell.$input[0].defaultValue, escapedDangerousHTML)
})

test('#class.formatter rounds numbers if they are numbers', function() {
  sandbox.stub(SubmissionCell.prototype, 'cellWrapper')
    .withArgs('0.67')
    .returns('ok')
  const formattedResponse = SubmissionCell.formatter(0, 0, {grade: 0.666}, {}, {})
  equal(formattedResponse, 'ok')
})

test('#class.formatter gives the value to the formatter if submission.grade isnt a parseable number', function() {
  sandbox.stub(SubmissionCell.prototype, 'cellWrapper')
    .withArgs('happy')
    .returns('ok')
  const formattedResponse = SubmissionCell.formatter(0, 0, {grade: 'happy'}, {}, {})
  equal(formattedResponse, 'ok')
})

test('#class.formatter adds a percent symbol for assignments with a percent grading_type', function() {
  sandbox.stub(SubmissionCell.prototype, 'cellWrapper')
    .withArgs('73%')
    .returns('ok')
  const formattedResponse = SubmissionCell.formatter(
    0,
    0,
    {grade: 73},
    {grading_type: 'percent'},
    {}
  )
  equal(formattedResponse, 'ok')
})

test('#class.formatter, isInactive adds grayed-out', () => {
  const student = {isInactive: true}
  const submissionCellResponse = SubmissionCell.formatter(0, 0, {grade: 'happy'}, {}, student)
  notEqual(submissionCellResponse.indexOf('grayed-out'), -1)
})

test('#class.formatter, isLocked: true adds grayed-out', () => {
  const submissionCellResponse = SubmissionCell.formatter(
    0,
    0,
    {grade: 73},
    {},
    {},
    {isLocked: true}
  )
  ok(submissionCellResponse.indexOf('grayed-out') > -1)
})

test('#class.formatter, isLocked: true adds cannot_edit', () => {
  const submissionCellResponse = SubmissionCell.formatter(
    0,
    0,
    {grade: 73},
    {},
    {},
    {isLocked: true}
  )
  ok(submissionCellResponse.indexOf('cannot_edit') > -1)
})

test('#class.formatter, isLocked: true does not include the cell comment bubble', () => {
  const submissionCellResponse = SubmissionCell.formatter(
    0,
    0,
    {grade: 73},
    {},
    {},
    {isLocked: true}
  )
  equal(submissionCellResponse.indexOf('gradebook-cell-comment'), -1)
})

test("#class.formatter, isLocked: false doesn't add grayed-out", () => {
  const submissionCellResponse = SubmissionCell.formatter(
    0,
    0,
    {grade: 73},
    {},
    {},
    {isLocked: false}
  )
  equal(submissionCellResponse.indexOf('grayed-out'), -1)
})

test("#class.formatter, isLocked: false doesn't add cannot_edit", () => {
  const submissionCellResponse = SubmissionCell.formatter(
    0,
    0,
    {grade: 73},
    {},
    {},
    {isLocked: false}
  )
  equal(submissionCellResponse.indexOf('cannot_edit'), -1)
})

test('#class.formatter, isLocked: false includes the cell comment bubble', () => {
  const submissionCellResponse = SubmissionCell.formatter(
    0,
    0,
    {grade: 73},
    {},
    {},
    {isLocked: false}
  )
  ok(submissionCellResponse.indexOf('gradebook-cell-comment') > -1)
})

test('#class.formatter, tooltip adds your text to the special classes', () => {
  const submissionCellResponse = SubmissionCell.formatter(
    0,
    0,
    {grade: 73},
    {},
    {},
    {tooltip: 'dora_the_explorer'}
  )
  ok(submissionCellResponse.indexOf('dora_the_explorer') > -1)
})

test("#class.formatter, isInactive: false doesn't add grayed-out", () => {
  const student = {isInactive: false}
  const submissionCellResponse = SubmissionCell.formatter(0, 0, {grade: 10}, {}, student)
  equal(submissionCellResponse.indexOf('grayed-out'), -1)
})

test('#class.formatter, isConcluded adds grayed-out', () => {
  const student = {isConcluded: true}
  const submissionCellResponse = SubmissionCell.formatter(0, 0, {grade: 10}, {}, student)
  notEqual(submissionCellResponse.indexOf('grayed-out'), -1)
})

test("#class.formatter, isConcluded doesn't have grayed-out", () => {
  const student = {isConcluded: false}
  const submissionCellResponse = SubmissionCell.formatter(0, 0, {grade: 10}, {}, student)
  equal(submissionCellResponse.indexOf('grayed-out'), -1)
})

test('#letter_grade.formatter, shows EX when submission is excused', function() {
  sandbox.stub(SubmissionCell.prototype, 'cellWrapper')
    .withArgs('EX')
    .returns('ok')
  const formattedResponse = SubmissionCell.letter_grade.formatter(0, 0, {excused: true}, {}, {})
  equal(formattedResponse, 'ok')
})

test('#letter_grade.formatter, shows the score and letter grade', function() {
  sandbox.stub(SubmissionCell.prototype, 'cellWrapper')
    .withArgs("F<span class='letter-grade-points'>0</span>")
    .returns('ok')
  const formattedResponse = SubmissionCell.letter_grade.formatter(
    0,
    0,
    {
      grade: 'F',
      score: 0
    },
    {},
    {}
  )
  equal(formattedResponse, 'ok')
})

test('#letter_grade.formatter, shows the letter grade', function() {
  sandbox.stub(SubmissionCell.prototype, 'cellWrapper')
    .withArgs('B')
    .returns('ok')
  const formattedResponse = SubmissionCell.letter_grade.formatter(0, 0, {grade: 'B'}, {}, {})
  equal(formattedResponse, 'ok')
})

test('#letter_grade.formatter, isLocked: true adds grayed-out', () => {
  const submissionCellResponse = SubmissionCell.letter_grade.formatter(
    0,
    0,
    {grade: 'A'},
    {},
    {},
    {isLocked: true}
  )
  ok(submissionCellResponse.indexOf('grayed-out') > -1)
})

test('#letter_grade.formatter, isLocked: true adds cannot_edit', () => {
  const submissionCellResponse = SubmissionCell.letter_grade.formatter(
    0,
    0,
    {grade: 'A'},
    {},
    {},
    {isLocked: true}
  )
  ok(submissionCellResponse.indexOf('cannot_edit') > -1)
})

test("#letter_grade.formatter, isLocked: false doesn't add grayed-out", () => {
  const submissionCellResponse = SubmissionCell.letter_grade.formatter(
    0,
    0,
    {grade: 'A'},
    {},
    {},
    {isLocked: false}
  )
  equal(submissionCellResponse.indexOf('grayed-out'), -1)
})

test("#letter_grade.formatter, isLocked: false doesn't add cannot_edit", () => {
  const submissionCellResponse = SubmissionCell.letter_grade.formatter(
    0,
    0,
    {grade: 'A'},
    {},
    {},
    {isLocked: false}
  )
  equal(submissionCellResponse.indexOf('cannot_edit'), -1)
})

test('#letter_grade.formatter, tooltip adds your text to the special classes', () => {
  const submissionCellResponse = SubmissionCell.letter_grade.formatter(
    0,
    0,
    {grade: 'A'},
    {},
    {},
    {tooltip: 'dora_the_explorer'}
  )
  ok(submissionCellResponse.indexOf('dora_the_explorer') > -1)
})

test('#gpa_scale.formatter, isLocked: true adds grayed-out', () => {
  const submissionCellResponse = SubmissionCell.gpa_scale.formatter(
    0,
    0,
    {grade: 3.2},
    {},
    {},
    {isLocked: true}
  )
  ok(submissionCellResponse.indexOf('grayed-out') > -1)
})

test('#gpa_scale.formatter, isLocked: true adds cannot_edit', () => {
  const submissionCellResponse = SubmissionCell.gpa_scale.formatter(
    0,
    0,
    {grade: 3.2},
    {},
    {},
    {isLocked: true}
  )
  ok(submissionCellResponse.indexOf('cannot_edit') > -1)
})

test("#gpa_scale.formatter, isLocked: false doesn't add grayed-out", () => {
  const submissionCellResponse = SubmissionCell.gpa_scale.formatter(
    0,
    0,
    {grade: 3.2},
    {},
    {},
    {isLocked: false}
  )
  equal(submissionCellResponse.indexOf('grayed-out'), -1)
})

test("#gpa_scale.formatter, isLocked: false doesn't add cannot_edit", () => {
  const submissionCellResponse = SubmissionCell.gpa_scale.formatter(
    0,
    0,
    {grade: 3.2},
    {},
    {},
    {isLocked: false}
  )
  equal(submissionCellResponse.indexOf('cannot_edit'), -1)
})

test('#gpa_scale.formatter, tooltip adds your text to the special classes', () => {
  const submissionCellResponse = SubmissionCell.gpa_scale.formatter(
    0,
    0,
    {grade: 3.2},
    {},
    {},
    {tooltip: 'dora_the_explorer'}
  )
  ok(submissionCellResponse.indexOf('dora_the_explorer') > -1)
})

test('#pass_fail.formatter, isLocked: true adds grayed-out', () => {
  const submissionCellResponse = SubmissionCell.pass_fail.formatter(
    0,
    0,
    {grade: 'complete'},
    {},
    {},
    {isLocked: true}
  )
  ok(submissionCellResponse.indexOf('grayed-out') > -1)
})

test('#pass_fail.formatter, isLocked: true adds cannot_edit', () => {
  const submissionCellResponse = SubmissionCell.pass_fail.formatter(
    0,
    0,
    {grade: 'complete'},
    {},
    {},
    {isLocked: true}
  )
  ok(submissionCellResponse.indexOf('cannot_edit') > -1)
})

test("#pass_fail.formatter, isLocked: false doesn't add grayed-out", () => {
  const submissionCellResponse = SubmissionCell.pass_fail.formatter(
    0,
    0,
    {grade: 'complete'},
    {},
    {},
    {isLocked: false}
  )
  equal(submissionCellResponse.indexOf('grayed-out'), -1)
})

test("#pass_fail.formatter, isLocked: false doesn't add cannot_edit", () => {
  const submissionCellResponse = SubmissionCell.pass_fail.formatter(
    0,
    0,
    {grade: 'complete'},
    {},
    {},
    {isLocked: false}
  )
  equal(submissionCellResponse.indexOf('cannot_edit'), -1)
})

test('#pass_fail.formatter, tooltip adds your text to the special classes', () => {
  const submissionCellResponse = SubmissionCell.pass_fail.formatter(
    0,
    0,
    {grade: 'complete'},
    {},
    {},
    {tooltip: 'dora_the_explorer'}
  )
  ok(submissionCellResponse.indexOf('dora_the_explorer') > -1)
})

test('#pass_fail.formatter, uses rawGrade to determine cssClass', () => {
  const submissionCellResponse = SubmissionCell.pass_fail.formatter(
    0,
    0,
    {
      grade: 'completo',
      rawGrade: 'complete'
    },
    {},
    {},
    {tooltip: 'dora_the_explorer'}
  )
  ok(submissionCellResponse.indexOf('gradebook-checkbox-pass') > -1)
})

test('#pass_fail.formatter, uses rawGrade to determine iconClass', () => {
  const submissionCellResponse = SubmissionCell.pass_fail.formatter(
    0,
    0,
    {
      grade: 'completo',
      rawGrade: 'complete'
    },
    {},
    {},
    {tooltip: 'dora_the_explorer'}
  )
  ok(submissionCellResponse.indexOf('icon-check') > -1)
})

QUnit.module('Pass/Fail SubmissionCell', {
  getCell(overrides = {}) {
    const opts = {
      item: {
        foo: {
          ...overrides.foo
        }
      },
      column: {
        field: 'foo',
        object: {points_possible: 100}
      },
      assignment: {},
      container: $('#fixtures')[0]
    }
    this.cell = new SubmissionCell.pass_fail(opts)
  },
  teardown() {
    $('#fixtures').empty()
  }
})

test('#pass_fail#htmlFromSubmission sets the data value for the button to entered_grade when it is complete', function() {
  this.getCell({foo: {entered_grade: 'complete'}})
  strictEqual(this.cell.$input.data('value'), 'complete')
})

test(
  '#pass_fail#htmlFromSubmission sets the data value for the button' +
    'to grade when it is complete and entered_grade is not present',
  function() {
    this.getCell({foo: {grade: 'complete'}})
    strictEqual(this.cell.$input.data('value'), 'complete')
  }
)

test('#pass_fail#htmlFromSubmission sets the data value for the button to entered_grade when it is incomplete', function() {
  this.getCell({foo: {entered_grade: 'incomplete'}})
  strictEqual(this.cell.$input.data('value'), 'incomplete')
})

test(
  '#pass_fail#htmlFromSubmission sets the data value for the button' +
    'to grade when it is incomplete and entered_grade is not present',
  function() {
    this.getCell({foo: {grade: 'incomplete'}})
    strictEqual(this.cell.$input.data('value'), 'incomplete')
  }
)

test("#pass_fail#transitionValue adds the 'dontblur' class so the user can continue toggling pass/fail state", function() {
  this.getCell()
  this.cell.$input = $('<button><i></i></button>')
  this.cell.transitionValue('pass')
  ok(this.cell.$input.hasClass('dontblur'))
})

test('#pass_fail#transitionValue changes the aria-label to match the currently selected option', function() {
  this.getCell()
  this.cell.$input = $('<button><i></i></button>')
  this.cell.transitionValue('fail')
  equal(this.cell.$input.attr('aria-label'), 'fail')
})

test('#pass_fail#transitionValue updates the icon class', function() {
  this.getCell()
  this.cell.$input = $('<button><i></i></button>')
  this.cell.transitionValue('pass')
  ok(this.cell.$input.find('i').hasClass('icon-check'))
})

test('#loadValue sets the value to entered_grade when available', function() {
  this.getCell({
    foo: {
      entered_grade: 'complete',
      grade: 'foo'
    }
  })
  this.cell.loadValue()
  strictEqual(this.cell.val, 'complete')
})

test('#loadValue sets the value to grade when entered_grade is not available', function() {
  this.getCell({foo: {grade: 'complete'}})
  this.cell.loadValue()
  strictEqual(this.cell.val, 'complete')
})

QUnit.module('SubmissionCell#classesBasedOnSubmission', () => {
  test('returns anonymous when anonymize_students is set on the assignment', () => {
    const assignment = {anonymize_students: true}
    strictEqual(SubmissionCell.classesBasedOnSubmission({}, assignment).includes('anonymous'), true)
  })

  test('does not return anonymous if anonymize_students is not set on the assignment', () => {
    strictEqual(SubmissionCell.classesBasedOnSubmission({}, {}).includes('anonymous'), false)
  })

  test('returns moderated when moderation_in_progress is set on the assignment', () => {
    const assignment = {moderation_in_progress: true}
    strictEqual(SubmissionCell.classesBasedOnSubmission({}, assignment).includes('moderated'), true)
  })

  test('returns moderated when muted and moderation_in_progress are set on the assignment', () => {
    const assignment = {moderation_in_progress: true, muted: true}
    strictEqual(SubmissionCell.classesBasedOnSubmission({}, assignment).includes('moderated'), true)
  })

  test('does not return moderated if moderation_in_progress is not set on the assignment', () => {
    strictEqual(SubmissionCell.classesBasedOnSubmission({}, {}).includes('moderated'), false)
  })

  test('does not return moderated if anonymize_students is set on the assignment', () => {
    const assignment = {anonymize_students: true}
    strictEqual(SubmissionCell.classesBasedOnSubmission({}, assignment).includes('moderated'), false)
  })

  test('returns muted when muted is set on the assignment', () => {
    const assignment = {muted: true}
    strictEqual(SubmissionCell.classesBasedOnSubmission({}, assignment).includes('muted'), true)
  })

  test('does not return muted when muted and moderation_in_progress are set on the assignment', () => {
    const assignment = {moderation_in_progress: true, muted: true}
    strictEqual(SubmissionCell.classesBasedOnSubmission({}, assignment).includes('muted'), false)
  })

  test('does not return muted when anonymize_students is set on the assignment', () => {
    const assignment = {anonymize_students: true}
    strictEqual(SubmissionCell.classesBasedOnSubmission({}, assignment).includes('muted'), false)
  })

  test('does not return muted if it is not set on the assignment', () => {
    strictEqual(SubmissionCell.classesBasedOnSubmission({}, {}).includes('muted'), false)
  })
})

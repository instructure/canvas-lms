#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'compiled/gradezilla/SubmissionCell'
  'str/htmlEscape'
  'jquery'
  'jsx/shared/helpers/numberHelper'
  'compiled/gradezilla/GradebookTranslations'
], (SubmissionCell, htmlEscape, $, numberHelper, GRADEBOOK_TRANSLATIONS) ->

  dangerousHTML= '"><img src=/ onerror=alert(document.cookie);>'
  escapedDangerousHTML = htmlEscape dangerousHTML

  QUnit.module "SubmissionCell",
    setup: ->
      @pointsPossible = 100
      @opts =
        item:
          'whatever': {}
        column:
          field: 'whatever'
          object:
            points_possible: @pointsPossible
        container: $('#fixtures')[0]
      @cell = new SubmissionCell @opts
    teardown: -> $('#fixtures').empty()

  test "#applyValue escapes html in passed state", ->
    item = whatever: {grade: '1'}
    state = dangerousHTML
    @stub @cell, 'postValue'
    @cell.applyValue(item,state)
    equal item.whatever.grade, escapedDangerousHTML

  test "#applyValue calls flashWarning", ->
    @stub @cell, 'postValue'
    flashWarningStub = @stub $, 'flashWarning'
    @cell.applyValue(@opts.item, '150')
    ok flashWarningStub.calledOnce

  test "#applyValue calls numberHelper with points possible", ->
    numberHelperStub = @stub(numberHelper, 'parse').withArgs(@pointsPossible)
    @stub @cell, 'postValue'
    @cell.applyValue(@opts.item, '10')

    strictEqual numberHelperStub.callCount, 1

  test "#applyValue calls numberHelper with state", ->
    state = '10'
    numberHelperStub = @stub(numberHelper, 'parse').withArgs(state)
    @stub @cell, 'postValue'
    @cell.applyValue(@opts.item, state)

    strictEqual numberHelperStub.callCount, 1

  test "#loadValue escapes html", ->
    @opts.item.whatever.grade = dangerousHTML
    @cell.loadValue()
    equal @cell.$input.val(), escapedDangerousHTML
    equal @cell.$input[0].defaultValue, escapedDangerousHTML

  test "#loadValue uses entered_grade when available", ->
    @opts.item.whatever.grade = '100'
    @opts.item.whatever.entered_grade = '110'
    @cell.loadValue()
    equal @cell.$input.val(), '110'
    equal @cell.$input[0].defaultValue, '110'

  test "#class.formatter rounds numbers if they are numbers", ->
    @stub(SubmissionCell.prototype, 'cellWrapper').withArgs('0.67').returns('ok')
    formattedResponse = SubmissionCell.formatter(0, 0, { grade: 0.666 }, {}, {})
    equal formattedResponse, 'ok'

  test "#class.formatter gives the value to the formatter if submission.grade isnt a parseable number", ->
    @stub(SubmissionCell.prototype, 'cellWrapper').withArgs('happy').returns('ok')
    formattedResponse = SubmissionCell.formatter(0, 0, { grade: 'happy' }, {}, {})
    equal formattedResponse, 'ok'

  test "#class.formatter adds a percent symbol for assignments with a percent grading_type", ->
    @stub(SubmissionCell.prototype, 'cellWrapper').withArgs("73%").returns('ok')
    formattedResponse = SubmissionCell.formatter(0, 0, { grade: 73 }, { grading_type: "percent" }, {})
    equal formattedResponse, 'ok'

  test "#class.formatter, isInactive adds grayed-out", ->
    student = { isInactive: true }
    submissionCellResponse = SubmissionCell.formatter(0, 0, { grade: 'happy'}, { }, student)
    notEqual submissionCellResponse.indexOf("grayed-out"), -1

  test "#class.formatter, isLocked: true adds grayed-out", ->
    submissionCellResponse = SubmissionCell.formatter(0, 0, { grade: 73 }, {}, {}, { isLocked: true })
    ok submissionCellResponse.indexOf("grayed-out") > -1

  test "#class.formatter, isLocked: true adds cannot_edit", ->
    submissionCellResponse = SubmissionCell.formatter(0, 0, { grade: 73 }, {}, {}, { isLocked: true })
    ok submissionCellResponse.indexOf("cannot_edit") > -1

  test "#class.formatter, isLocked: false doesn't add grayed-out", ->
    submissionCellResponse = SubmissionCell.formatter(0, 0, { grade: 73 }, {}, {}, { isLocked: false })
    equal submissionCellResponse.indexOf("grayed-out"), -1

  test "#class.formatter, isLocked: false doesn't add cannot_edit", ->
    submissionCellResponse = SubmissionCell.formatter(0, 0, { grade: 73 }, {}, {}, { isLocked: false })
    equal submissionCellResponse.indexOf("cannot_edit"), -1

  test "#class.formatter, isInactive: false doesn't add grayed-out", ->
    student = { isInactive: false }
    submissionCellResponse = SubmissionCell.formatter(0, 0, { grade: 10 }, { }, student)
    equal submissionCellResponse.indexOf("grayed-out"), -1

  test "#class.formatter, isConcluded adds grayed-out", ->
    student = { isConcluded: true }
    submissionCellResponse = SubmissionCell.formatter(0, 0, { grade: 10 }, { }, student)
    notEqual submissionCellResponse.indexOf("grayed-out"), -1

  test "#class.formatter, isConcluded doesn't have grayed-out", ->
    student = { isConcluded: false }
    submissionCellResponse = SubmissionCell.formatter(0, 0, { grade: 10 }, { }, student)
    equal submissionCellResponse.indexOf("grayed-out"), -1

  test "#letter_grade.formatter, shows Excused when submission is excused", ->
    @stub(SubmissionCell.prototype, 'cellWrapper').withArgs('Excused').returns('ok')
    formattedResponse = SubmissionCell.letter_grade.formatter(0, 0, {excused:true}, {}, {})
    equal formattedResponse, 'ok'

  test "#letter_grade.formatter, shows the score and letter grade", ->
    @stub(SubmissionCell.prototype, 'cellWrapper').withArgs('F<span class=\'letter-grade-points\'>0</span>').returns('ok')
    formattedResponse = SubmissionCell.letter_grade.formatter(0, 0, {grade: 'F', score: 0 }, {}, {})
    equal formattedResponse, 'ok'

  test "#letter_grade.formatter, shows the letter grade", ->
    @stub(SubmissionCell.prototype, 'cellWrapper').withArgs('B').returns('ok')
    formattedResponse = SubmissionCell.letter_grade.formatter(0, 0, {grade: 'B'}, {}, {})
    equal formattedResponse, 'ok'

  test "#letter_grade.formatter, isLocked: true adds grayed-out", ->
    submissionCellResponse = SubmissionCell.letter_grade.formatter(0, 0, { grade: "A" }, {}, {}, { isLocked: true })
    ok submissionCellResponse.indexOf("grayed-out") > -1

  test "#letter_grade.formatter, isLocked: true adds cannot_edit", ->
    submissionCellResponse = SubmissionCell.letter_grade.formatter(0, 0, { grade: "A" }, {}, {}, { isLocked: true })
    ok submissionCellResponse.indexOf("cannot_edit") > -1

  test "#letter_grade.formatter, isLocked: false doesn't add grayed-out", ->
    submissionCellResponse = SubmissionCell.letter_grade.formatter(0, 0, { grade: "A" }, {}, {}, { isLocked: false })
    equal submissionCellResponse.indexOf("grayed-out"), -1

  test "#letter_grade.formatter, isLocked: false doesn't add cannot_edit", ->
    submissionCellResponse = SubmissionCell.letter_grade.formatter(0, 0, { grade: "A" }, {}, {}, { isLocked: false })
    equal submissionCellResponse.indexOf("cannot_edit"), -1

  test "#gpa_scale.formatter, isLocked: true adds grayed-out", ->
    submissionCellResponse = SubmissionCell.gpa_scale.formatter(0, 0, { grade: 3.2 }, {}, {}, { isLocked: true })
    ok submissionCellResponse.indexOf("grayed-out") > -1

  test "#gpa_scale.formatter, isLocked: true adds cannot_edit", ->
    submissionCellResponse = SubmissionCell.gpa_scale.formatter(0, 0, { grade: 3.2 }, {}, {}, { isLocked: true })
    ok submissionCellResponse.indexOf("cannot_edit") > -1

  test "#gpa_scale.formatter, isLocked: false doesn't add grayed-out", ->
    submissionCellResponse = SubmissionCell.gpa_scale.formatter(0, 0, { grade: 3.2 }, {}, {}, { isLocked: false })
    equal submissionCellResponse.indexOf("grayed-out"), -1

  test "#gpa_scale.formatter, isLocked: false doesn't add cannot_edit", ->
    submissionCellResponse = SubmissionCell.gpa_scale.formatter(0, 0, { grade: 3.2 }, {}, {}, { isLocked: false })
    equal submissionCellResponse.indexOf("cannot_edit"), -1

  test "#pass_fail.formatter, isLocked: true adds grayed-out", ->
    submissionCellResponse = SubmissionCell.pass_fail.formatter(0, 0, { grade: "complete" }, {}, {}, { isLocked: true })
    ok submissionCellResponse.indexOf("grayed-out") > -1

  test "#pass_fail.formatter, isLocked: true adds cannot_edit", ->
    submissionCellResponse = SubmissionCell.pass_fail.formatter(0, 0, { grade: "complete" }, {}, {}, { isLocked: true })
    ok submissionCellResponse.indexOf("cannot_edit") > -1

  test "#pass_fail.formatter, isLocked: false doesn't add grayed-out", ->
    submissionCellResponse = SubmissionCell.pass_fail.formatter(0, 0, { grade: "complete" }, {}, {}, { isLocked: false })
    equal submissionCellResponse.indexOf("grayed-out"), -1

  test "#pass_fail.formatter, isLocked: false doesn't add cannot_edit", ->
    submissionCellResponse = SubmissionCell.pass_fail.formatter(0, 0, { grade: "complete" }, {}, {}, { isLocked: false })
    equal submissionCellResponse.indexOf("cannot_edit"), -1

  test "#pass_fail.formatter, uses rawGrade to determine cssClass", ->
    submissionCellResponse = SubmissionCell.pass_fail.formatter(0, 0, { grade: "completo", rawGrade: "complete" }, {}, {})
    ok submissionCellResponse.indexOf("gradebook-checkbox-pass") > -1

  test "#pass_fail.formatter, uses rawGrade to determine iconClass", ->
    submissionCellResponse = SubmissionCell.pass_fail.formatter(0, 0, { grade: "completo", rawGrade: "complete" }, {}, {})
    ok submissionCellResponse.indexOf("icon-check") > -1

  QUnit.module "Pass/Fail SubmissionCell",
    getCell: (overrides = {}) ->
      opts =
        item:
          foo: Object.assign({}, overrides.foo)
        column:
          field: 'foo'
          object:
            points_possible: 100
        assignment: {}
        container: $('#fixtures')[0]

      @cell = new SubmissionCell.pass_fail opts

    teardown: -> $('#fixtures').empty()

  test "#pass_fail#htmlFromSubmission sets the data value for the button to entered_grade when it is complete", ->
    @getCell({ foo: { entered_grade: 'complete' }})
    strictEqual(@cell.$input.data('value'), 'complete')

  test "#pass_fail#htmlFromSubmission sets the data value for the button to entered_grade when it is incomplete", ->
    @getCell({ foo: { entered_grade: 'incomplete' }})
    strictEqual(@cell.$input.data('value'), 'incomplete')

  test "#pass_fail#transitionValue changes the aria-label to match the currently selected option", ->
    @getCell()
    @cell.$input = $("<button><i></i></button>")
    @cell.transitionValue('incomplete')
    equal @cell.$input.attr('aria-label'), 'fail'

  test "#pass_fail#transitionValue updates the icon class", ->
    @getCell()
    @cell.$input = $("<button><i></i></button>")
    @cell.transitionValue('complete')
    ok @cell.$input.find('i').hasClass('icon-check')

  QUnit.module ".styles"

  test "when submission and assignment are empty, return nothing", ->
    deepEqual SubmissionCell.styles(), []

  test "when submission is dropped it returns dropped", ->
    deepEqual SubmissionCell.styles({ drop: true }), ["dropped"]

  test "when submission is not dropped it returns nothing", ->
    deepEqual SubmissionCell.styles({ drop: false }), []

  test "when submission's 'drop' property is undefined it returns nothing", ->
    deepEqual SubmissionCell.styles({ drop: undefined }), []

  test "when submission is excused it returns dropped", ->
    deepEqual SubmissionCell.styles({ excused: true }), ["excused"]

  test "when submission is not excused it returns nothing", ->
    deepEqual SubmissionCell.styles({ excused: false }), []

  test "when submission's 'excused' property is undefined it returns nothing", ->
    deepEqual SubmissionCell.styles({ excused: undefined }), []

  test "when submission's grade does not match the current submission it returns resubmitted", ->
    deepEqual SubmissionCell.styles({ grade_matches_current_submission: false }), ["resubmitted"]

  test "when submission's grade matches the current submission it returns resubmitted", ->
    deepEqual SubmissionCell.styles({ grade_matches_current_submission: true }), []

  test "when submission's 'grade_matches_current_submission' property is undefined it returns nothing", ->
    deepEqual SubmissionCell.styles({ grade_matches_current_submission: undefined }), []

  test "when a submission is missing it returns missing", ->
    deepEqual SubmissionCell.styles({ missing: true }), ["missing"]

  test "when a submission is not missing it returns nothing", ->
    deepEqual SubmissionCell.styles({ missing: false }), []

  test "when a submission's 'missing' property is undefined it returns nothing", ->
    deepEqual SubmissionCell.styles({ missing: undefined }), []

  test "when a submission is late it returns late", ->
    deepEqual SubmissionCell.styles({ late: true }), ["late"]

  test "when a submission is not late it returns nothing", ->
    deepEqual SubmissionCell.styles({ late: false }), []

  test "when a submission's 'late' property is undefined it return nothing", ->
    deepEqual SubmissionCell.styles({ late: undefined }), []

  test "when an assignment's is ungraded it returns ungraded", ->
    assignment = {}
    deepEqual SubmissionCell.styles(assignment, { submission_types: ["not_graded"] }), ["ungraded"]

  test "when an assignment's is not ungraded it returns nothing", ->
    assignment = {}
    deepEqual SubmissionCell.styles(assignment, { submission_types: ['online_text_entry'] }), []

  test "when an assignment's type is undefined it return nothing", ->
    assignment = {}
    deepEqual SubmissionCell.styles(assignment, { submission_types: undefined }), []

  test "when an assignment is muted it returns muted", ->
    assignment = {}
    deepEqual SubmissionCell.styles(assignment, { muted: true }), ["muted"]

  test "when an assignment is not muted it returns nothing", ->
    assignment = {}
    deepEqual SubmissionCell.styles(assignment, { muted: false }), []

  test "when an assignment submission's 'mute' property is undefined it return nothing", ->
    assignment = {}
    deepEqual SubmissionCell.styles(assignment, { muted: undefined }), []

  test "when a submission has a type it is returned", ->
    deepEqual SubmissionCell.styles({ submission_type: "fake_type" }), ["fake_type"]

  test "when a submission has no type it returns nothing", ->
    deepEqual SubmissionCell.styles({ submission_type: '' }), []

  test "when a submission's submitions_type is undefined it return nothing", ->
    deepEqual SubmissionCell.styles({ submission_type: undefined }), []

  test "when a submission is late, ungraded, muted and has a submission type", ->
    submission =
      late: true
      submission_type: "online_text_entry"
    assignment =
      submission_types: ["not_graded"]
      muted: true
    deepEqual SubmissionCell.styles(submission, assignment), [
      'late',
      'ungraded',
      'muted',
      'online_text_entry'
    ]

  test "when a submission is both dropped and excused, dropped takes priority", ->
    deepEqual SubmissionCell.styles({ drop: true, excused: true }), ['dropped']

  test "when a submission is both excused and resubmitted, excused takes priority", ->
    deepEqual SubmissionCell.styles({ excused: true, grade_matches_current_submission: false }), ['excused']

  test "when a submission is both resubmitted and missing, missing takes priority", ->
    deepEqual SubmissionCell.styles({ grade_matches_current_submission: false, late: true }), ['resubmitted']

  test "when a submission is both missing and late, missing takes priority", ->
    deepEqual SubmissionCell.styles({ missing: true, late: true }), ['missing']

  test "when all criteria are present, the styles are dropped, ungraded, muted, and the submission_type", ->
    submission =
      drop: true
      excused: true
      grade_matches_current_submission: false
      missing: true
      late: true
      submission_type: "online_text_entry"
    assignment =
      submission_types: ["not_graded"]
      muted: true
    deepEqual SubmissionCell.styles(submission, assignment), [
      "dropped",
      "ungraded",
      "muted",
      "online_text_entry"
    ]

  QUnit.module "#cellWrapper",
    setup: ->
      @fixtures = document.querySelector('#fixtures')

    params: ->
      item:
        'whatever':
          id: '1'
          submission_type: "online_text_entry"
      column:
        field: 'whatever'
        object:
          id: '42'

    teardown: ->
      @fixtures.innerHTML = ''

  test "if student is inactive, styles include 'grayed-out'", ->
    cell = (new SubmissionCell(@params())).cellWrapper('', { student: { isInactive: true } })
    @fixtures.innerHTML = cell
    strictEqual @fixtures.querySelectorAll('div.grayed-out').length, 1

  test "if student is concluded, styles include 'grayed-out'", ->
    @fixtures.innerHTML = (new SubmissionCell(@params())).cellWrapper('', { student: { isConcluded: true } })
    strictEqual @fixtures.querySelectorAll('div.grayed-out').length, 1

  test "if isLocked, styles include 'grayed-out'", ->
    @fixtures.innerHTML = (new SubmissionCell(@params())).cellWrapper('', { isLocked: true })
    strictEqual @fixtures.querySelectorAll('div.grayed-out').length, 1

  test "if student is inactive, tooltips include 'grayed-out'", ->
    @fixtures.innerHTML = (new SubmissionCell(@params())).cellWrapper('', { student: { isInactive: true } })
    strictEqual @fixtures.querySelectorAll('div.grayed-out').length, 1

  test "if student is concluded, styles include 'grayed-out'", ->
    @fixtures.innerHTML = (new SubmissionCell(@params())).cellWrapper('', { student: { isConcluded: true } })
    strictEqual @fixtures.querySelectorAll('div.grayed-out').length, 1

  test "if locked, styles include 'grayed-out'", ->
    @fixtures.innerHTML = (new SubmissionCell(@params())).cellWrapper('', { isLocked: true })
    strictEqual @fixtures.querySelectorAll('div.grayed-out').length, 1

  test "if student is concluded, styles include 'cannot_edit'", ->
    @fixtures.innerHTML = (new SubmissionCell(@params())).cellWrapper('', { student: { isConcluded: true } })
    strictEqual @fixtures.querySelectorAll('div.cannot_edit').length, 1

  test "if is locked, styles include 'cannot_edit'", ->
    @fixtures.innerHTML = (new SubmissionCell(@params())).cellWrapper('', { isLocked: true })
    strictEqual @fixtures.querySelectorAll('div.cannot_edit').length, 1

  test "if it has turnitin data, styles includes 'turnitin'", ->
    params = @params()
    params.item.whatever.turnitin_data = { submission_1: 'none' }
    @fixtures.innerHTML = (new SubmissionCell(params)).cellWrapper('')
    strictEqual @fixtures.querySelectorAll('div.turnitin').length, 1

  test "if no turnitin data, styles do not includes 'turnitin'", ->
    @fixtures.innerHTML = (new SubmissionCell(@params()).cellWrapper(''))
    strictEqual @fixtures.querySelectorAll('div.turnitin').length, 0

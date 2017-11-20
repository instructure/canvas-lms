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
  'compiled/gradebook/SubmissionCell'
  'str/htmlEscape'
  'jquery'
  'jsx/shared/helpers/numberHelper'
], (SubmissionCell, htmlEscape, $, numberHelper) ->

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

  test "#class.formatter, isLocked: true does not include the cell comment bubble", ->
    submissionCellResponse = SubmissionCell.formatter(0, 0, { grade: 73 }, {}, {}, { isLocked: true })
    equal submissionCellResponse.indexOf("gradebook-cell-comment"), -1

  test "#class.formatter, isLocked: false doesn't add grayed-out", ->
    submissionCellResponse = SubmissionCell.formatter(0, 0, { grade: 73 }, {}, {}, { isLocked: false })
    equal submissionCellResponse.indexOf("grayed-out"), -1

  test "#class.formatter, isLocked: false doesn't add cannot_edit", ->
    submissionCellResponse = SubmissionCell.formatter(0, 0, { grade: 73 }, {}, {}, { isLocked: false })
    equal submissionCellResponse.indexOf("cannot_edit"), -1

  test "#class.formatter, isLocked: false includes the cell comment bubble", ->
    submissionCellResponse = SubmissionCell.formatter(0, 0, { grade: 73 }, {}, {}, { isLocked: false })
    ok submissionCellResponse.indexOf("gradebook-cell-comment") > -1

  test "#class.formatter, tooltip adds your text to the special classes", ->
    submissionCellResponse = SubmissionCell.formatter(0, 0, { grade: 73 }, {}, {}, { tooltip: "dora_the_explorer" })
    ok submissionCellResponse.indexOf("dora_the_explorer") > -1

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

  test "#letter_grade.formatter, shows EX when submission is excused", ->
    @stub(SubmissionCell.prototype, 'cellWrapper').withArgs('EX').returns('ok')
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

  test "#letter_grade.formatter, tooltip adds your text to the special classes", ->
    submissionCellResponse = SubmissionCell.letter_grade.formatter(0, 0, { grade: "A" }, {}, {}, { tooltip: "dora_the_explorer" })
    ok submissionCellResponse.indexOf("dora_the_explorer") > -1

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

  test "#gpa_scale.formatter, tooltip adds your text to the special classes", ->
    submissionCellResponse = SubmissionCell.gpa_scale.formatter(0, 0, { grade: 3.2 }, {}, {}, { tooltip: "dora_the_explorer" })
    ok submissionCellResponse.indexOf("dora_the_explorer") > -1

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

  test "#pass_fail.formatter, tooltip adds your text to the special classes", ->
    submissionCellResponse = SubmissionCell.pass_fail.formatter(0, 0, { grade: "complete" }, {}, {}, { tooltip: "dora_the_explorer" })
    ok submissionCellResponse.indexOf("dora_the_explorer") > -1

  test "#pass_fail.formatter, uses rawGrade to determine cssClass", ->
    submissionCellResponse = SubmissionCell.pass_fail.formatter(0, 0, { grade: "completo", rawGrade: "complete" }, {}, {}, { tooltip: "dora_the_explorer" })
    ok submissionCellResponse.indexOf("gradebook-checkbox-pass") > -1

  test "#pass_fail.formatter, uses rawGrade to determine iconClass", ->
    submissionCellResponse = SubmissionCell.pass_fail.formatter(0, 0, { grade: "completo", rawGrade: "complete" }, {}, {}, { tooltip: "dora_the_explorer" })
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

  test "#pass_fail#transitionValue adds the 'dontblur' class so the user can continue toggling pass/fail state", ->
    @getCell()
    @cell.$input = $("<button><i></i></button>")
    @cell.transitionValue("pass")
    ok @cell.$input.hasClass('dontblur')

  test "#pass_fail#transitionValue changes the aria-label to match the currently selected option", ->
    @getCell()
    @cell.$input = $("<button><i></i></button>")
    @cell.transitionValue('fail')
    equal @cell.$input.attr('aria-label'), 'fail'

  test "#pass_fail#transitionValue updates the icon class", ->
    @getCell()
    @cell.$input = $("<button><i></i></button>")
    @cell.transitionValue('pass')
    ok @cell.$input.find('i').hasClass('icon-check')

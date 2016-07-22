define [
  'compiled/gradebook2/SubmissionCell'
  'str/htmlEscape'
  'jquery'
], (SubmissionCell, htmlEscape, $) ->

  dangerousHTML= '"><img src=/ onerror=alert(document.cookie);>'
  escapedDangerousHTML = htmlEscape dangerousHTML

  module "SubmissionCell",
    setup: ->
      @opts =
        item:
            'whatever': {}
        column:
            field: 'whatever'
            object:
              points_possible: 100
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

  test "#loadValue escapes html", ->
    @opts.item.whatever.grade = dangerousHTML
    @cell.loadValue()
    equal @cell.$input.val(), escapedDangerousHTML
    equal @cell.$input[0].defaultValue, escapedDangerousHTML

  test "#class.formatter rounds numbers if they are numbers", ->
    @stub(SubmissionCell.prototype, 'cellWrapper').withArgs(0.67).returns('ok')
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

  test "#class.formatter, isInactive: false doesn't add grayed-out", ->
    student = { isInactive: false }
    submissionCellResponse = SubmissionCell.formatter(0, 0, { grade: 10}, { }, student)
    equal submissionCellResponse.indexOf("grayed-out"), -1

  test "#class.formatter, isConcluded adds grayed-out", ->
    student = { isConcluded: true }
    submissionCellResponse = SubmissionCell.formatter(0, 0, { grade: 10}, { }, student)
    notEqual submissionCellResponse.indexOf("grayed-out"), -1

  test "#class.formatter, isConcluded doesn't have grayed-out", ->
    student = { isConcluded: false }
    submissionCellResponse = SubmissionCell.formatter(0, 0, { grade: 10}, { }, student)
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

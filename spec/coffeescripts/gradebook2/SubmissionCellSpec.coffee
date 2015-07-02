define [
  'compiled/gradebook2/SubmissionCell'
  'str/htmlEscape'
  'jquery'
], (SubmissionCell,htmlEscape,$) ->

  dangerousHTML= '"><img src=/ onerror=alert(document.cookie);>'
  escapedDangerousHTML = htmlEscape dangerousHTML

  module "SubmissionCell",
    setup: ->
      @opts =
        item:
            'whatever': {}
        column:
            field: 'whatever'
            object: {}
        container: $('#fixtures')[0]
      @cell = new SubmissionCell @opts
    teardown: -> $('#fixtures').empty()

  test "#applyValue escapes html in passed state", ->
    item = whatever: {grade: '1'}
    state = dangerousHTML
    @stub @cell, 'postValue'
    @cell.applyValue(item,state)
    equal item.whatever.grade, escapedDangerousHTML

  test "#loadValue escapes html", ->
    @opts.item.whatever.grade = dangerousHTML
    @cell.loadValue()
    equal @cell.$input.val(), escapedDangerousHTML
    equal @cell.$input[0].defaultValue, escapedDangerousHTML

  test "#class.formatter rounds numbers if they are numbers", ->
    @stub(SubmissionCell.prototype, 'cellWrapper').withArgs(0.67).returns('ok')
    formattedResponse = SubmissionCell.formatter(0,0,{grade: 0.666})
    equal formattedResponse, 'ok'

  test "#class.formatter gives the value to the formatter if submission.grade isnt a parseable number", ->
    @stub(SubmissionCell.prototype, 'cellWrapper').withArgs('happy').returns('ok')
    formattedResponse = SubmissionCell.formatter(0,0,{grade: 'happy'})
    equal formattedResponse, 'ok'

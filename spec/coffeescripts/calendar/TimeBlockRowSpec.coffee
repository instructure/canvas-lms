define [
  'jquery'
  'compiled/calendar/TimeBlockList'
  'compiled/calendar/TimeBlockRow'
], ($, TimeBlockList, TimeBlockRow) ->

  nextYear = new Date().getFullYear() + 1
  start    = new Date("2/3/#{nextYear} 5:32")
  end      = new Date("2/3/#{nextYear} 10:32")

  module "TimeBlockRow",
    setup: ->
      @$holder = $('<table />').appendTo(document.body)
      @timeBlockList = new TimeBlockList(@$holder)

      # fakeTimer'd because the tests with failed validations add an error box
      # that is faded in. if we don't tick past the fade-in, other unrelated
      # tests that use fake timers fail.
      @clock = sinon.useFakeTimers((new Date()).valueOf())

    teardown: ->
      # tick past any remaining errorBox fade-ins
      @clock.tick 250
      @clock.restore()
      @$holder.detach()

  test "should init properly", ->
    me = new TimeBlockRow(@timeBlockList, {start, end})
    # make sure the <input> `value`s are right
    equal me.inputs.date.$el.val().trim(),       start.toString("ddd MMM d, yyyy")
    equal me.inputs.start_time.$el.val().trim(), start.toString("h:mm") + start.toString("tt").toLowerCase()
    equal me.inputs.end_time.$el.val().trim(),     end.toString("h:mm") +   end.toString("tt").toLowerCase()

  test "delete link", ->
    me = @timeBlockList.addRow({start, end})
    ok (me in @timeBlockList.rows), 'make sure I am in the timeBlockList to start out with'
    me.$row.find('.delete-block-link').click()

    ok !(me in @timeBlockList.rows)
    ok !me.$row[0].parentElement, 'make sure I am no longer on the page'

  for inputName in TimeBlockRow::inputNames
    test "validateField: #{inputName}", ->
      me = new TimeBlockRow(@timeBlockList, {start, end})
      ok me.validateField(inputName), 'validates with good info'
      me.updateDom(inputName, 'asdf').change()
      ok !me.validateField(inputName), 'doesnt validate with invalid input'
      ok me.inputs[inputName].$el.hasClass('error')

      me.updateDom(inputName, '').change()
      ok me.validateField(inputName), 'valid if blank'
      ok !me.inputs[inputName].$el.hasClass('error'), 'no error classes if valid'

  test 'validate: with good data', ->
    me = new TimeBlockRow(@timeBlockList, {start, end})
    ok me.validate(), 'whole row validates if has good info'

  test 'validate: date in past', ->
    me = new TimeBlockRow(@timeBlockList, {start, end})
    me.updateDom('date', '1/1/2000').change()
    ok !me.validate()
    ok me.inputs.end_time.$el.data('associated_error_box').is(':visible'), 'error box is visible'
    ok me.inputs.end_time.$el.hasClass('error'), 'has error class'

  test 'validate: just time in past', ->
    twelveOClock = new Date(new Date().toDateString())
    twelveOOne = new Date(twelveOClock)
    twelveOOne.setMinutes(1)

    me = new TimeBlockRow(@timeBlockList, {start: twelveOClock, end: twelveOOne})
    ok !me.validate(), 'not valid if time in past'
    ok me.inputs.end_time.$el.data('associated_error_box').is(':visible'), 'error box is visible'
    ok me.inputs.end_time.$el.hasClass('error'), 'has error class'

  test 'validate: end before start', ->
    me = new TimeBlockRow(@timeBlockList, {start: end, end: start})
    ok !me.validate()
    ok me.inputs.start_time.$el.data('associated_error_box').parents('body'), 'error box is visible'
    ok me.inputs.start_time.$el.hasClass('error'), 'has error class'

  test 'valid if whole row is blank', ->
    me = new TimeBlockRow(@timeBlockList)
    ok me.blank()
    ok me.validate()

  test 'getData', ->
    me = new TimeBlockRow(@timeBlockList, {start, end})
    me.validate()
    deepEqual me.getData(), [start, end, false]


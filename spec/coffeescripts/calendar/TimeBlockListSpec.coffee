# requires jquery and date.js
define [
  'jquery'
  'compiled/calendar/TimeBlockList'
  'moment'
  'compiled/util/fcUtil'
], ($, TimeBlockList, moment, fcUtil) ->

  QUnit.module "TimeBlockList",
    setup: ->
      wrappedDate = (str) ->
        moment( new Date(str))

      @$holder = $('<table>').appendTo("#fixtures")
      @$splitter = $('<a>').appendTo("#fixtures")
      # make all of these dates in next year to gaurentee the are in the future
      nextYear = new Date().getFullYear() + 1
      @blocks = [
        [wrappedDate("2/3/#{nextYear} 5:32"), wrappedDate("2/3/#{nextYear} 10:32") ]
        # a locked one
        [wrappedDate("2/3/#{nextYear} 11:15"), wrappedDate("2/3/#{nextYear} 15:01"), true]
        [wrappedDate("2/3/#{nextYear} 16:00"), wrappedDate("2/3/#{nextYear} 19:00")]
      ]
      @blankRow = { date: fcUtil.wrap(new Date(2017, 2, 3)) }
      @me = new TimeBlockList(@$holder, @$splitter, @blocks, @blankRow)

    teardown: ->
      @$holder.detach()
      @$splitter.detach()
      $("#fixtures").empty()
      $(".ui-tooltip").remove()

  test "should init properly", ->
    equal @me.rows.length, 3+1, 'three rows + 1 blank'

  test "should not include locked or blank rows in .blocks()", ->
    deepEqual @me.blocks(), [@blocks[0], @blocks[2]]

  test "should not render custom date in blank row if more than one time block already", ->
    equal(@me.rows[3].$date.val(), '')

  test "should handle intialization of locked / unlocked rows", ->
    ok !@me.rows[0].locked, 'first row should not be locked'
    ok @me.rows[1].locked, 'second row should be locked'

  test 'should remove rows correctly', ->
    # get rid of every row
    for row in @me.rows
      row.remove()
      ok !(row in @me.rows)

    # make sure there is still a blank row if we got rid of everything
    ok @me.rows.length, 1
    ok @me.rows[0].blank()

  test 'should add rows correctly', ->
    rowsBefore = @me.rows.length
    data = [Date.parse('next tuesday at 7pm'), Date.parse('next tuesday at 8pm') ]
    row = @me.addRow(data)
    equal @me.rows.length, rowsBefore + 1
    ok $.contains(@me.element, row.$row), 'make sure the element got appended to my <tbody>'

  test "should validate if all rows are valid and complete or blank", ->
    ok @me.validate(), 'should validate'

  test "should not not validate if all rows are not valid", ->
    row = @me.addRow()
    row.$date.val('asdfasdf').change()
    ok !@me.validate(), 'should not validate'

  test "should not validate if a row is incomplete", ->
    row = @me.addRow()
    row.$start_time.val('7pm').change()
    ok !@me.validate(), 'should not validate'

  test "should still validate if a row is fully blank", ->
    row = @me.addRow()
    ok @me.validate(), 'should validate'

  test "should alert when invalid", ->
    row = @me.addRow()
    row.$date.val('asdfasdf').change()
    spy = @spy(window, 'alert')
    @me.validate()
    ok spy.called, 'should `alert` a message'

  test "should split correctly", ->
    @me.rows[2].remove()
    @me.split('30')

    equal @me.rows.length, 12
    equal @me.blocks().length, 10

  QUnit.module "TimeBlockList with no time blocks",
    setup: ->
      wrappedDate = (str) ->
        moment( new Date(str))

      @$holder = $('<table>').appendTo("#fixtures")
      @$splitter = $('<a>').appendTo("#fixtures")
      @blocks = []
      @blankRow = { date: fcUtil.wrap(new Date(2050, 2, 3)) }
      @me = new TimeBlockList(@$holder, @$splitter, @blocks, @blankRow)

    teardown: ->
      @$holder.detach()
      @$splitter.detach()
      $("#fixtures").empty()
      $(".ui-tooltip").remove()

  test "should render custom date in blank row if provided", ->
    equal(@me.rows[0].$date.val(), 'Thu Mar 3, 2050')

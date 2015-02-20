# requires jquery and date.js
define [
  'jquery'
  'compiled/calendar/TimeBlockList'
], ($, TimeBlockList) ->

  module "TimeBlockList",
    setup: ->
      @$holder = $('<table>').appendTo(document.body)
      @$splitter = $('<a>').appendTo(document.body)
      # make all of these dates in next year to gaurentee the are in the future
      nextYear = new Date().getFullYear() + 1
      @blocks = [
        [new Date("2/3/#{nextYear} 5:32"), new Date("2/3/#{nextYear} 10:32") ]
        # a locked one
        [new Date("2/3/#{nextYear} 11:15"), new Date("2/3/#{nextYear} 15:01"), true ]
        [new Date("2/3/#{nextYear} 16:00"), new Date("2/3/#{nextYear} 19:00")]
      ]
      @me = new TimeBlockList(@$holder, @$splitter, @blocks)

    teardown: ->
      @$holder.detach()
      @$splitter.detach()

  test "should init properly", ->
    equal @me.rows.length, 3+1, 'three rows + 1 blank'

  test "should not include locked or blank rows in .blocks()", ->
    deepEqual @me.blocks(), [@blocks[0], @blocks[2]]


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

  test "should not not validate if all rows are not valid", ->
    ok @me.validate(), 'should validate if has valid dates'

    # make an invalid row
    row =  @me.addRow()
    row.updateDom('date', 'asdfasdf').change()

    # todo, use sinon to mock alert when it lands in master
    _alert = window.alert
    calledAlert = false
    window.alert = -> calledAlert = true
    ok !@me.validate(), 'should not validate with asdf dates'
    ok calledAlert, 'should `alert` a message'
    window.alert = _alert #restore native alert

  test "should split correctly", ->
    @me.rows[2].remove()
    @me.split('30')

    equal @me.rows.length, 12
    equal @me.blocks().length, 10

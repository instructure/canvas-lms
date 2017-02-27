define ['jquery', 'compiled/calendar/TimeBlockListManager', 'moment'], ($, TimeBlockListManager, moment) ->
  QUnit.module "TimeBlockListManager",
    setup: ->
    teardown: ->
      $("#ui-datepicker-div").empty()

  test "constructor", ->
    d1 = moment(new Date(2011, 12, 27,  9,  0))
    d2 = moment(new Date(2011, 12, 27,  9, 30))
    d3 = moment(new Date(2011, 12, 27, 10,  0))
    d4 = moment(new Date(2011, 12, 27, 11, 30))

    manager = new TimeBlockListManager([[d1, d2], [d3, d4]])

    equal manager.blocks.length, 2
    equal manager.blocks[0].start.format(), d1.format()
    equal manager.blocks[0].end.format(), d2.format()
    equal manager.blocks[1].start.format(), d3.format()
    equal manager.blocks[1].end.format(), d4.format()

  test "consolidate", ->
    manager = new TimeBlockListManager()

    d1 = moment(new Date(2011, 12, 27,  9,  0))
    d2 = moment(new Date(2011, 12, 27,  9, 30))
    d3 = moment(new Date(2011, 12, 27, 10,  0))
    d4 = moment(new Date(2011, 12, 27, 11, 30))
    manager.add d1                            , d2
    manager.add d3                            , moment(new Date(2011, 12, 27, 10, 30))
    manager.add new Date(2011, 12, 27, 10, 30), moment(new Date(2011, 12, 27, 11,  0))
    manager.add new Date(2011, 12, 27, 11,  0), d4
    manager.add d4                            , moment(new Date(2011, 12, 27, 12, 30)), true

    manager.consolidate()

    equal manager.blocks.length, 3
    equal manager.blocks[0].start.format(), d1.format()
    equal manager.blocks[0].end.format(), d2.format()
    equal manager.blocks[1].start.format(), d3.format()
    equal manager.blocks[1].end.format(), d4.format()
    equal manager.blocks[2].start.format(), d4.format() # doesn't consolidate because of lock

  test "split", ->
    manager = new TimeBlockListManager()

    d1 = moment(new Date 2011, 12, 27,  9,  0)
    d2 = moment(new Date 2011, 12, 27,  9, 30)
    d3 = moment(new Date 2011, 12, 27, 10, 30)
    d4 = moment(new Date 2011, 12, 27, 11,  0)
    d5 = moment(new Date 2011, 12, 27, 11, 25)
    d6 = moment(new Date 2011, 12, 27, 10, 0)
    d7 = moment(new Date 2011, 12, 27, 12, 0)
    d8 = moment(new Date 2011, 12, 27, 15, 0)
    manager.add d1, d2
    manager.add d2, d3
    manager.add d4, d5
    manager.add d7, d8, true
    manager.split(30)

    equal manager.blocks.length, 5

    expectedTimes = [d1, d2, d2, d6, d6,d3, d4, d5, d7, d8]
    while (expectedTimes.length > 0)
      block = manager.blocks.shift()
      equal block.start.format(), expectedTimes.shift().format()
      equal block.end.format(), expectedTimes.shift().format()

  test "delete", ->
    manager = new TimeBlockListManager()
    d1 = moment(new Date(2011, 12, 27, 7, 0))
    d2 = moment(new Date(2011, 12, 27, 9, 0))
    manager.add d1                          , moment(new Date(2011, 12, 27, 7, 30))
    manager.add moment(new Date(2011, 12, 27, 8, 0)), moment(new Date(2011, 12, 27, 8, 30))
    manager.add d2                          , moment(new Date(2011, 12, 27, 9, 30)), true

    manager.delete 3
    equal manager.blocks.length, 3

    manager.delete 1
    equal manager.blocks.length, 2
    equal manager.blocks[0].start.format(), d1.format()
    equal manager.blocks[1].start.format(), d2.format()

    manager.delete 1  # shouldn't delete because of lock
    equal manager.blocks.length, 2

  test "reset", ->
    manager = new TimeBlockListManager()
    manager.add moment(new Date(2011, 12, 27, 8, 0)), moment(new Date(2011, 12, 27, 8, 30))
    manager.reset()
    equal manager.blocks.length, 0

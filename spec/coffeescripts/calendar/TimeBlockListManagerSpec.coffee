define ['compiled/calendar/TimeBlockListManager'], (TimeBlockListManager) ->
  module "TimeBlockListManager"

  test "constructor", ->
    d1 = new Date(2011, 12, 27,  9,  0)
    d2 = new Date(2011, 12, 27,  9, 30)
    d3 = new Date(2011, 12, 27, 10,  0)
    d4 = new Date(2011, 12, 27, 11, 30)

    manager = new TimeBlockListManager([[d1, d2], [d3, d4]])

    equal manager.blocks.length, 2
    equal manager.blocks[0].start, d1
    equal manager.blocks[0].end, d2
    equal manager.blocks[1].start, d3
    equal manager.blocks[1].end, d4

  test "consolidate", ->
    manager = new TimeBlockListManager()

    d1 = new Date(2011, 12, 27,  9,  0)
    d2 = new Date(2011, 12, 27,  9, 30)
    d3 = new Date(2011, 12, 27, 10,  0)
    d4 = new Date(2011, 12, 27, 11, 30)
    manager.add d1                            , d2
    manager.add d3                            , new Date(2011, 12, 27, 10, 30)
    manager.add new Date(2011, 12, 27, 10, 30), new Date(2011, 12, 27, 11,  0)
    manager.add new Date(2011, 12, 27, 11,  0), d4
    manager.add d4                            , new Date(2011, 12, 27, 12, 30), true

    manager.consolidate()

    equal manager.blocks.length, 3
    equal manager.blocks[0].start, d1
    equal manager.blocks[0].end, d2
    equal manager.blocks[1].start, d3
    equal manager.blocks[1].end, d4
    equal manager.blocks[2].start, d4 # doesn't consolidate because of lock

  test "split", ->
    manager = new TimeBlockListManager()

    d1 = new Date 2011, 12, 27,  9,  0
    d2 = new Date 2011, 12, 27,  9, 30
    d3 = new Date 2011, 12, 27, 10, 30
    d4 = new Date 2011, 12, 27, 11,  0
    d5 = new Date 2011, 12, 27, 11, 25
    d6 = new Date 2011, 12, 27, 10, 0
    d7 = new Date 2011, 12, 27, 12, 0
    d8 = new Date 2011, 12, 27, 15, 0
    manager.add d1, d2
    manager.add d2, d3
    manager.add d4, d5
    manager.add d7, d8, true
    manager.split(30)

    equal manager.blocks.length, 5

    expectedTimes = [d1, d2, d2, d6, d6,d3, d4, d5, d7, d8]
    while (expectedTimes.length > 0)
      block = manager.blocks.shift()
      equal block.start.getTime(), expectedTimes.shift().getTime()
      equal block.end.getTime(), expectedTimes.shift().getTime()

  test "delete", ->
    manager = new TimeBlockListManager()
    d1 = new Date(2011, 12, 27, 7, 0)
    d2 = new Date(2011, 12, 27, 9, 0)
    manager.add d1                          , new Date(2011, 12, 27, 7, 30)
    manager.add new Date(2011, 12, 27, 8, 0), new Date(2011, 12, 27, 8, 30)
    manager.add d2                          , new Date(2011, 12, 27, 9, 30), true

    manager.delete 3
    equal manager.blocks.length, 3

    manager.delete 1
    equal manager.blocks.length, 2
    equal manager.blocks[0].start, d1
    equal manager.blocks[1].start, d2

    manager.delete 1  # shouldn't delete because of lock
    equal manager.blocks.length, 2

  test "reset", ->
    manager = new TimeBlockListManager()
    manager.add new Date(2011, 12, 27, 8, 0), new Date(2011, 12, 27, 8, 30)
    manager.reset()
    equal manager.blocks.length, 0

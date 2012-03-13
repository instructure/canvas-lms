define [
  'compiled/widget/CustomList'
  'helpers/simulateClick'
  'helpers/loadFixture'
], (CustomList, simulateClick, loadFixture)->
  module 'CustomList',
    setup: ->
      @fixture = loadFixture 'CustomList'
      items = window.items = []
      for index in [0..100]
        items.push
          id: index
          shortName: "Course #{index}"
          longName: "Course long #{index}"
          subtitle: "Enrolled as Teacher"
          href: "/courses/#{index}"

      @list = new CustomList @fixture.find('#customList'), items,
        url: 'fixtures/ok.json'
        appendTarget: @fixture.find('#customList')
      @list.open()
      @lis = @fixture.find('.customListItem')
      @clock = sinon.useFakeTimers()

    teardown: ->
      @clock.restore()
      @fixture.detach()

  test 'should open and close', ->
    @list.close()
    @clock.tick 1
    equal @list.wrapper.is(':visible'), false, 'starts hidden'

    @list.open()
    @clock.tick 1
    equal @list.wrapper.is(':visible'), true, 'displays on open'

  test 'should remove and add the first item', ->
    # store original length to compare to later
    originalLength = @list.targetList.children().length

    # click an element to remove it from the list
    simulateClick( @lis[0] )

    # this next click should get ignored because the previous element is animating
    simulateClick( @lis[1] )

    @clock.tick 300
    expectedLength = originalLength - 1
    equal @list.pinned.length, expectedLength, 'only one item should have been removed'

    simulateClick( @lis[0] )
    @clock.tick 300
    equal @list.pinned.length, originalLength, 'item should be restored'

  test 'should cancel pending add request on remove', ->
    # Add one that doesn't exist
    el = jQuery @lis[16]
    @list.add(16, el)
    @clock.tick 300
    ok @list.requests.add[16], 'create an "add" request'

    # then immediately remove it before the request has time to come back
    item = @list.pinned.findBy 'id', 16
    @list.remove item, el
    @clock.tick 300
    equal @list.requests.add[16], undefined, 'delete "add" request'

  test 'should cancel pending remove request on add', ->
    el = jQuery @lis[1]
    item = @list.pinned.findBy('id', 1)
    @list.remove(item, el)
    @clock.tick 300
    ok @list.requests.remove[1], 'create a "remove" request'

    @list.add 1, el
    @clock.tick 300
    equal @list.requests.remove[1], undefined, 'delete "remove" request'

  test 'should reset', ->
    originalLength = @list.targetList.children().length
    simulateClick @lis[0]
    @clock.tick 300
    ok originalLength isnt @list.targetList.children().length, 'length should be different'

    @list.reset()
    length = @list.targetList.children().length
    equal length, originalLength, 'targetList items restored'


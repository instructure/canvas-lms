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

    teardown: ->
      @fixture.detach()

  test 'should open and close', ->
    @list.close()
    equal @list.wrapper.is(':visible'), false, 'starts hidden'
    @list.open()
    equal @list.wrapper.is(':visible'), true, 'displays on open'

  asyncTest 'should remove and add the first item', 2, ->
    # store original length to compare to later
    originalLength = @list.targetList.children().length

    # click an element to remove it from the list
    simulateClick( @lis[0] )

    # this next click should get ignored because the previous element is animating
    simulateClick( @lis[1] )

    setTimeout =>
      expectedLength = originalLength - 1
      equal @list.pinned.length, expectedLength, 'only one item should have been removed'
      simulateClick( @lis[0] )
      equal @list.pinned.length, originalLength, 'item should be restored'
      start()
    , 300

  test 'should cancel pending add request on remove', ->
    # Add one that doesn't exist
    el = jQuery @lis[16]
    @list.add(16, el)
    ok @list.requests.add[16], 'create an "add" request'

    # then immediately remove it before the request has time to come back
    item = @list.pinned.findBy 'id', 16
    @list.remove item, el
    equal @list.requests.add[16], undefined, 'delete "add" request'

  test 'should cancel pending remove request on add', ->
    el = jQuery @lis[1]
    item = @list.pinned.findBy('id', 1)
    @list.remove(item, el)
    ok @list.requests.remove[1], 'create a "remove" request'

    @list.add 1, el
    equal @list.requests.remove[1], undefined, 'delete "remove" request'

  asyncTest 'should reset', 2, ->
    originalLength = @list.targetList.children().length
    simulateClick @lis[0]

    setTimeout =>
      ok originalLength isnt @list.targetList.children().length, 'length should be different'

      @list.reset()
      length = @list.targetList.children().length
      equal length, originalLength, 'targetList items restored'
      start()
    , 300


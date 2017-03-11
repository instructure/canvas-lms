define [
  'jquery'
  'compiled/widget/CustomList'
  'helpers/jquery.simulate'
], ($,CustomList)->
  QUnit.module 'CustomList',
    setup: ->
      @el = $("""<div>
        <style>
        #customList,
        .customListWrapper { border: solid 1px; width: 300px; }

        .customListWrapper { position: absolute; left: 350px; top: 80px;}

        #customList ul,
        .customListWrapper ul,
        .customListGhost { padding: 0; margin: 0; list-style: none; width: 300px;}

        #customList li,
        .customListWrapper li,
        .customListGhost li { padding: 0px; border-top: solid 1px; width: 100%;}

        #customList li a,
        .customListWrapper li a,
        .customListGhost li a{ display: block; padding: 10px; background: #fff;}

        .customListGhost li { border: solid 1px;}

        .customListWrapper ul { height: 400px; overflow: auto; }

        .customListWrapper li.on a { background: #ccc; }
        </style>


        <div id="customList">

          <button class="customListOpen">Edit this list</button>

          <ul id="list" class="menu-item-drop-column-list">
            <li data-id="0">
              <a href="/courses/0">
                <span class="name ellipsis" title="Course 0">Course 0</span>
                <span class="subtitle ellipsis">Enrolled as: <b>Teacher</b></span>
              </a>
            </li>
            <li data-id="1">
              <a href="/courses/1">
                <span class="name ellipsis" title="Course 1">Course 1</span>
                <span class="subtitle ellipsis">Enrolled as: <b>Teacher</b></span>
              </a>
            </li>
            <li data-id="10">
              <a href="/courses/10">
                <span class="name ellipsis" title="Course 10">Course 10</span>
                <span class="subtitle ellipsis">Enrolled as: <b>Teacher</b></span>
              </a>
            </li>
            <li data-id="11">
              <a href="/courses/11">
                <span class="name ellipsis" title="Course 11">Course 11</span>
                <span class="subtitle ellipsis">Enrolled as: <b>Teacher</b></span>
              </a>
            </li>
            <li data-id="2">
              <a href="/courses/2">
                <span class="name ellipsis" title="Course 2">Course 2</span>
                <span class="subtitle ellipsis">Enrolled as: <b>Teacher</b></span>
              </a>
            </li>
            <li data-id="3">
              <a href="/courses/3">
                <span class="name ellipsis" title="Course 3">Course 3</span>
                <span class="subtitle ellipsis">Enrolled as: <b>Teacher</b></span>
              </a>
            </li>
            <li data-id="4">
              <a href="/courses/4">
                <span class="name ellipsis" title="Course 4">Course 4</span>
                <span class="subtitle ellipsis">Enrolled as: <b>Teacher</b></span>
              </a>
            </li>
            <li data-id="5">
              <a href="/courses/5">
                <span class="name ellipsis" title="Course 5">Course 5</span>
                <span class="subtitle ellipsis">Enrolled as: <b>Teacher</b></span>
              </a>
            </li>
            <li data-id="6">
              <a href="/courses/6">
                <span class="name ellipsis" title="Course 6">Course 6</span>
                <span class="subtitle ellipsis">Enrolled as: <b>Teacher</b></span>
              </a>
            </li>
            <li data-id="7">
              <a href="/courses/7">
                <span class="name ellipsis" title="Course 7">Course 7</span>
                <span class="subtitle ellipsis">Enrolled as: <b>Teacher</b></span>
              </a>
            </li>
            <li data-id="8">
              <a href="/courses/8">
                <span class="name ellipsis" title="Course 8">Course 8</span>
                <span class="subtitle ellipsis">Enrolled as: <b>Teacher</b></span>
              </a>
            </li>
            <li data-id="9">
              <a href="/courses/9">
                <span class="name ellipsis" title="Course 9">Course 9</span>
                <span class="subtitle ellipsis">Enrolled as: <b>Teacher</b></span>
              </a>
            </li>
          </ul>
        </div>
       </div>
       """)
      $('#fixtures').append(@el)

      items = window.items = []
      for index in [0..100]
        items.push
          id: index
          shortName: "Course #{index}"
          longName: "Course long #{index}"
          subtitle: "Enrolled as Teacher"
          href: "/courses/#{index}"

      @list = new CustomList @el.find('#customList'), items,
        url: 'fixtures/ok.json'
        appendTarget: @el.find('#customList')
      @list.open()
      @lis = @el.find('.customListItem')
      @clock = sinon.useFakeTimers()

    teardown: ->
      @clock.restore()
      @el.remove()
      $(".customListGhost").remove()

  test 'should open and close', ->
    @list.close()
    @clock.tick 1
    equal @list.wrapper.is(':visible'), false, 'starts hidden'

    @list.open()
    @clock.tick 1
    equal @list.wrapper.is(':visible'), true, 'displays on open'

#  test 'should remove and add the first item', ->
#    # store original length to compare to later
#    originalLength = @list.pinned.length
#
#    # click an element to remove it from the list
#    $(@lis[0]).simulate('click')
#
#    # this next click should get ignored because the previous element is animating
#    $(@lis[1]).simulate('click')
#
#    @clock.tick 300
#    expectedLength = originalLength - 1
#    equal @list.pinned.length, expectedLength, 'only one item should have been removed'
#
#    $(@lis[0]).simulate('click')
#    @clock.tick 300
#    equal @list.pinned.length, originalLength, 'item should be restored'

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
    el = jQuery @lis[0]
    item = @list.pinned.findBy('id', 0)
    @list.remove(item, el)
    @clock.tick 300
    ok @list.requests.remove[0], 'create a "remove" request'

    @list.add 0, el
    @clock.tick 300
    equal @list.requests.remove[0], undefined, 'delete "remove" request'

#  test 'should reset', ->
#    originalLength = @list.targetList.children().length
#    $(@lis[0]).simulate('click')
#    @clock.tick 300
#    ok originalLength isnt @list.targetList.children().length, 'length should be different'
#
#    @list.reset()
#    length = @list.targetList.children().length
#    equal length, originalLength, 'targetList items restored'

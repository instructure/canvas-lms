#
# Copyright (C) 2012 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

define [
  'compiled/widget/ScrollableList',
  'helpers/loadFixture'
], (ScrollableList, loadFixture) ->

  module 'ScrollableList',

    setup: ->
      @fakeApi = (options={}) ->
        numItems  = options.numItems  ? 100
        sort      = options.sort      ? 'asc'
        callbacks = options.callbacks ? []
        @itemIds = (i*2 for i in [1..numItems])
        @itemIds.reverse() if sort is 'desc'
        @items = for id in @itemIds
          {id: id, sortBy: id, value: "item #{id}", visible: true}

        @requestCount = 0
        (request) =>
          @requestCount++
          callbacks[@requestCount]?(request)
          page = 1
          perPage = 25
          if match = request.url.match(/[&\?]page=(\d+)/)
            page = parseInt(match[1]) - 1
          if match = request.url.match(/per_page=(\d+)/)
            perPage = parseInt(match[1])
          items = @items[(page * perPage) ... (page + 1) * perPage]
          response = [
            200
            { 'Content-Type': 'application/json' }
            JSON.stringify({items: items, item_ids: @itemIds})
          ]
          request.respond response...

      @fixture = loadFixture 'ScrollableList'
      @$container = $('#scrollable_list_container')
      @clock  = sinon.useFakeTimers()
      @server = sinon.fakeServer.create()

      class DummyModel
        constructor: (attributes) ->
          @attributes = {}
          @set(attributes)
        get: (key) ->
          @[key]
        set: (attributes) ->
          for key, value of attributes
            @attributes[key] = value
            @[key] = value
          this
        toJSON: ->
          @attributes

      @defaults =
        itemTemplate: (opts) -> "<li>#{opts['value']}</li>"
        baseUrl: '/api/v1/test.json'
        fetchBuffer: 1
        perPage: 5
        model: DummyModel

    teardown: ->
      @clock.restore()
      @server.restore()
      @fixture.detach()

  test 'should load the initial data plus the buffer', ->
    @server.respondWith(/.+/, @fakeApi())

    @list = new ScrollableList @$container, $.extend({}, @defaults, fetchBuffer: 6)
    @server.respond()

    # only 5 are visible, but we got two extra pages due to the fetchBuffer
    equal @requestCount, 3
    equal @$container.find('li').length, 15
    equal @$container.find('li').text(), ("item #{i*2}" for i in [1..15]).join('')
    # space is reserved for all 100 elements
    equal @$container.find('ul').height(), 2000

  test 'should load everything around the visible section as the user scrolls', ->
    fakeApi = @fakeApi callbacks:
      3: =>
        # empty placeholders should have been created for everything through
        # the scrolled spot (plus the buffer)
        equal @$container.find('li').length, 56

    @server.respondWith(/.+/, fakeApi)

    @list = new ScrollableList @$container, $.extend({}, @defaults, fetchBuffer: 1)

    @server.respond()
    equal @requestCount, 2
    equal @$container.find('li').text(), ("item #{i*2}" for i in [1..10]).join('')
    equal @$container.find('ul').height(), 2000

    @$container.scrollTop(1000)
    @list.scroll() # handler is async, so we have to call this explicitly :(
    @clock.tick 500

    @server.respond()
    equal @requestCount, 5
    equal @$container.find('li').text(), ("item #{i*2}" for i in [1..10]).join('') + # the initial stuff,
                                         ("item #{i*2}" for i in [46..60]).join('') # plus the area we scrolled to

  test 'should re-fetch already-fetched data if the data changes underneath us', ->
    fakeApi = @fakeApi callbacks:
      3: => # tweak the dataset right before the third request returns
        @items.splice(0, 1)
        @itemIds.splice(0, 1)
    @server.respondWith(/.+/, fakeApi)

    @list = new ScrollableList @$container, $.extend({}, @defaults, fetchBuffer: 11)
    @server.respond()

    equal @requestCount, 6 # pages 1, 2, 3, 4, 1, 2
    equal @$container.find('li').length, 20
    equal @$container.find('li').text(), ("item #{i*2}" for i in [2..21]).join('')

  test 'should add an item', ->
    @server.respondWith(/.+/, @fakeApi())

    @list = new ScrollableList @$container, @defaults
    @server.respond()

    equal @requestCount, 2
    equal @$container.find('li').text(), ("item #{i*2}" for i in [1..10]).join('')
    @list.addItem id: 3, sortBy: 3, value: "item 3", visible: true
    equal @$container.find('li').text(), ("item #{i}" for i in [2,3,4,6,8,10,12,14,16,18,20]).join('')
    equal @$container.find('ul').height(), 2020

  test 'should add an item even if its section isn\'t loaded yet', ->
    @server.respondWith(/.+/, @fakeApi())

    @list = new ScrollableList @$container, @defaults
    @server.respond()

    equal @requestCount, 2
    equal @$container.find('li').text(), ("item #{i*2}" for i in [1..10]).join('')
    item = id: 21, sortBy: 21, value: "item 21", visible: true
    @items.splice(10, 0, item)
    @itemIds.splice(10, 0, 21)
    @list.addItem item
    @server.respond()
    result = ("item #{i*2}" for i in [1..14])
    result.splice(10, 0, "item 21")
    equal @$container.find('li').text(), result.join('')
    equal @$container.find('ul').height(), 2020

  test 'should remove an item', ->
    @server.respondWith(/.+/, @fakeApi())

    @list = new ScrollableList @$container, @defaults
    @server.respond()

    equal @requestCount, 2
    equal @$container.find('li').text(), ("item #{i*2}" for i in [1..10]).join('')
    @list.removeItem @items.splice(1, 1)[0]
    @itemIds.splice(1, 1)
    @clock.tick 500
    equal @$container.find('li').text(), ("item #{i}" for i in [2,6,8,10,12,14,16,18,20]).join('')
    equal @$container.find('ul').height(), 1980
    @server.respond() # fills in the previously loaded page
    equal @$container.find('li').text(), ("item #{i}" for i in [2,6,8,10,12,14,16,18,20,22]).join('')

  test 'should update an item', ->
    @server.respondWith(/.+/, @fakeApi())

    @list = new ScrollableList @$container, @defaults
    @server.respond()

    equal @requestCount, 2
    equal @$container.find('li').text(), ("item #{i*2}" for i in [1..10]).join('')
    @list.updateItems [{id: 2, sortBy: 2, value: "lol", visible: true}]
    equal @$container.find('li').text(), ["lol"].concat("item #{i*2}" for i in [2..10]).join('')

  test 'should remove an item if no longer visible', ->
    @server.respondWith(/.+/, @fakeApi())

    @list = new ScrollableList @$container, @defaults
    @server.respond()

    equal @requestCount, 2
    equal @$container.find('li').text(), ("item #{i*2}" for i in [1..10]).join('')
    item = @items.splice(1, 1)[0]
    item.visible = false
    @itemIds.splice(1, 1)
    @list.updateItems [item]
    @clock.tick 500
    equal @$container.find('li').text(), ("item #{i}" for i in [2,6,8,10,12,14,16,18,20]).join('')
    equal @$container.find('ul').height(), 1980
    @server.respond() # fills in the previously loaded page
    equal @$container.find('li').text(), ("item #{i}" for i in [2,6,8,10,12,14,16,18,20,22]).join('')

  test 'should move an item', ->
    @server.respondWith(/.+/, @fakeApi())
    @list = new ScrollableList @$container, $.extend({}, @defaults, sortKey: 'sortBy')
    @server.respond()

    equal @requestCount, 2
    equal @$container.find('li').text(), ("item #{i*2}" for i in [1..10]).join('')
    item = @items[0]
    item.sortBy = 5
    @list.updateItems [item]
    # visible in at old and new location during transition
    equal @$container.find('li').text(), ("item #{i}" for i in [2,4,2,6,8,10,12,14,16,18,20]).join('')
    @clock.tick 500
    equal @$container.find('li').text(), ("item #{i}" for i in [4,2,6,8,10,12,14,16,18,20]).join('')

  test 'should do a synchronous re-render if multiple items are updated/moved', ->
    @server.respondWith(/.+/, @fakeApi())
    @list = new ScrollableList @$container, $.extend({}, @defaults, sortKey: 'sortBy')
    @server.respond()

    equal @requestCount, 2
    equal @$container.find('li').text(), ("item #{i*2}" for i in [1..10]).join('')
    item1 = @items[0]
    item1.sortBy = 5
    item2 = @items[2]
    item2.sortBy = 1
    @list.updateItems [item1, item2]
    equal @$container.find('li').text(), ("item #{i}" for i in [6,4,2,8,10,12,14,16,18,20]).join('')

  test 'should move an item into an unloaded section', ->
    @server.respondWith(/.+/, @fakeApi())
    @list = new ScrollableList @$container, $.extend({}, @defaults, sortKey: 'sortBy')
    @server.respond()

    equal @requestCount, 2
    equal @$container.find('li').text(), ("item #{i*2}" for i in [1..10]).join('')
    item = @items.splice(0, 1)[0]
    item.sortBy = 25
    @itemIds.splice(0, 1)
    @itemIds.splice(11, 0, item.id)
    @items.splice(11, 0, item)
    @list.updateItems [item]

    # visible at old location during transition
    equal @$container.find('li').text(), ("item #{i}" for i in [2,4,6,8,10,12,14,16,18,20]).join('')
    @clock.tick 500
    # since we don't know where it's going yet, we don't remove it
    equal @$container.find('li').text(), ("item #{i}" for i in [2,4,6,8,10,12,14,16,18,20]).join('')
    # fetches new id list
    @server.respond()
    # re-completes page 2 and loads page 3
    @server.respond()
    equal @$container.find('li').text(), ("item #{i}" for i in [4,6,8,10,12,14,16,18,20,22,24,2,26,28,30]).join('')

  test 'should move an item from an unloaded section', ->
    @server.respondWith(/.+/, @fakeApi())
    @list = new ScrollableList @$container, $.extend({}, @defaults, sortKey: 'sortBy')
    @server.respond()

    equal @requestCount, 2
    equal @$container.find('li').text(), ("item #{i*2}" for i in [1..10]).join('')

    # now move it up
    item = @items.splice(19, 1)[0]
    item.sortBy = 1
    @itemIds.splice(19, 1)
    @itemIds.splice(0, 0, item.id)
    @items.splice(0, 0, item)
    @list.updateItems [item]

    # visible at old location during transition
    equal @$container.find('li').text(), ("item #{i}" for i in [40,2,4,6,8,10,12,14,16,18,20,40]).join('')
    @clock.tick 500
    # yay, moved up!
    equal @$container.find('li').text(), ("item #{i}" for i in [40,2,4,6,8,10,12,14,16,18,20]).join('')

  test 'should disable while initializing or resetting', ->
    @server.respondWith(/.+/, @fakeApi())
    @list = new ScrollableList @$container, @defaults

    @clock.tick 20
    equal @$container.css('opacity'), "0.5"
    @server.respond()
    equal @$container.css('opacity'), "1"

    @list.load(params: foo: "foo")
    @clock.tick 20
    equal @$container.css('opacity'), "0.5"
    @server.respond()
    equal @$container.css('opacity'), "1"

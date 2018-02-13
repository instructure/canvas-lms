#
# Copyright (C) 2012 - present Instructure, Inc.
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

define [
  'jquery'
  'underscore'
  'compiled/xhr/RemoteSelect'
], ($, _, RemoteSelect) ->
  QUnit.module 'RemoteSelect',
    setup: ->
      @response = [200, { 'Content-Type': 'application/json' }, '[{ "label": "one", "value": 1 }, {"label": "two", "value": 2 }]']
      @el       = $('<select id="test-select"></select>').appendTo('#fixtures')

    teardown: ->
      @el.remove()
      document.getElementById("fixtures").innerHTML = ""

  test 'should load results into a select', ->
    server = sinon.fakeServer.create()
    server.respondWith(/.+/, @response)

    rs = new RemoteSelect(@el, url: '/test/url.json')
    ok @el.prop('disabled')

    server.respond()
    equal @el.children().length, 2
    server.restore()

  test 'should load an object as <optgroup>', ->
    @response.pop()
    @response.push JSON.stringify {
      'Group One': [
        { label: 'One', value: 1 }
        { label: 'Two', value: 2 }
      ]
      'Group Two': [
        { label: 'Three', value: 3 }
        { label: 'Four', value: 4 }
      ]
    }

    server = sinon.fakeServer.create()
    server.respondWith(/.+/, @response)

    rs = new RemoteSelect(@el, url: '/test/url.json')
    server.respond()
    equal @el.children('optgroup').length, 2
    equal @el.find('option').length, 4
    server.restore()

  test 'should cache responses', ->
    server = sinon.fakeServer.create()
    server.respondWith(/.+/, @response)
    @spy($, 'getJSON')

    rs = new RemoteSelect(@el, url: '/test/cached.json')
    server.respond()

    ok $.getJSON.calledOnce
    equal _.keys(rs.cache.store).length, 1
    server.restore()

  test 'should accept a formatter', ->
    server = sinon.fakeServer.create()
    @response.pop()
    @response.push JSON.stringify [
      { group: 'one', name: 'one', id: 1 }
      { group: 'one', name: 'two', id: 2 }
      { group: 'two', name: 'three', id: 3 }
      { group: 'two', name: 'four', id: 4 }
    ]
    server.respondWith(/.+/, @response)

    format = (data) ->
      groups = _.groupBy data, (obj) -> obj.group
      _.each groups, (group, key) ->
        groups[key] = _.map group, (item) ->
          label: item.name, value: item.id
      groups

    rs = new RemoteSelect(@el,
      formatter: format
      url: '/test/url.json')
    server.respond()

    equal @el.children('optgroup').length, 2
    equal @el.find('option').length, 4
    server.restore()

  test 'should take params', ->
    server = sinon.fakeServer.create()
    @spy($, 'getJSON')

    rs = new RemoteSelect(@el,
      url: '/test/url.json',
      requestParams: { param: 'value' })

    ok $.getJSON.calledWith '/test/url.json', { param: 'value' }, rs.onResponse
    rs.spinner.remove()
    server.restore()

  test 'should include original options in select', ->
    server = sinon.fakeServer.create()
    server.respondWith(/.+/, @response)
    @el.append '<option value="">Default</option>'

    rs = new RemoteSelect(@el, url: '/test/url.json')
    server.respond()

    equal @el.children().length, 3
    server.restore()

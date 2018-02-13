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
  'compiled/PaginatedList'
], ($, PaginatedList) ->
  paginatedListFixture = """
    <h3>Paginated List Spec</h3>
    <div id="list-wrapper">
      <ul></ul>
    </div>
    """

  QUnit.module 'PaginatedList',
    setup: ->
      # server response
      @response = [200, { 'Content-Type': 'application/json' }, '[{ "value": "one" }, { "value": "two" }]']
      # fake template (mimics a handlebars function)
      @template = (opts) ->
        tpl = (opt) ->
          "<li>#{opt['value']}</li>"
        (tpl(opt) for opt in opts).join ''
      @fixture = $(paginatedListFixture).appendTo('#fixtures')
      @el =
        wrapper: $('#list-wrapper')
        list: $('#list-wrapper').find('ul')
      @clock  = sinon.useFakeTimers()
      @server = sinon.fakeServer.create()
    teardown: ->
      @clock.restore()
      @server.restore()
      @fixture.remove()

  test 'should fetch and display results', ->
    @server.respondWith(/.+/, @response)

    new PaginatedList @el.wrapper,
      template: @template
      url: '/api/v1/test.json'
    @server.respond()
    @clock.tick 500

    equal @el.list.children().length, 2

  test 'should display a view more link if next page is available', ->
    @server.respondWith(/.+/, [@response[0], { 'Content-Type': 'application/json', 'Link': 'rel="next"' }, @response[2]])

    new PaginatedList @el.wrapper,
      template: @template
      url: '/api/v1/test.json'
    @server.respond()
    @clock.tick 500

    ok @el.wrapper.find('.view-more-link').length > 0

  test 'should not display a view more link if there is no next page', ->
    @server.respondWith(/.+/, @response)

    new PaginatedList @el.wrapper,
      template: @template
      url: '/api/v1/test.json'
    @server.respond()
    @clock.tick 500

    ok @el.wrapper.find('.view-more-link').length is 0

  test 'should accept a template function', ->
    @server.respondWith(/.+/, @response)

    new PaginatedList @el.wrapper,
      template: @template
      url: '/api/v1/test.json'
    @server.respond()
    @clock.tick 500

    equal @el.list.find('li:first-child').text(), 'one'
    equal @el.list.find('li:last-child').text(), 'two'

  test 'should accept a presenter function', ->
    @server.respondWith(/.+/, @response)

    new PaginatedList @el.wrapper,
      presenter: (list) ->
        ({ value: 'changed' } for l in list)
      template: @template
      url: '/api/v1/test.json'
    @server.respond()
    @clock.tick 500

    equal @el.list.find('li:first-child').text(), 'changed'

  test 'should allow user to defer getJSON', ->
    @spy($, 'getJSON')
    new PaginatedList @el.wrapper,
      start: false
      template: @template,
      url: '/api/v1/not-called.json'

    equal $.getJSON.callCount, 0

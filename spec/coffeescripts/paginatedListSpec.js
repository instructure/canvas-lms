/*
 * Copyright (C) 2012 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import $ from 'jquery'
import PaginatedList from 'compiled/PaginatedList'

const paginatedListFixture = `
  <h3>Paginated List Spec</h3>
  <div id="list-wrapper">
    <ul></ul>
  </div>
`

QUnit.module('PaginatedList', {
  setup() {
    this.response = [
      200,
      {'Content-Type': 'application/json'},
      '[{ "value": "one" }, { "value": "two" }]'
    ]

    // fake template (mimics a handlebars function)
    this.template = opts => opts.map(opt => `<li>${opt.value}</li>`).join('')
    this.fixture = $(paginatedListFixture).appendTo('#fixtures')
    this.el = {
      wrapper: $('#list-wrapper'),
      list: $('#list-wrapper').find('ul')
    }
    this.clock = sinon.useFakeTimers()
    this.server = sinon.fakeServer.create()
  },
  teardown() {
    this.clock.restore()
    this.server.restore()
    this.fixture.remove()
  }
})

test('should fetch and display results', function() {
  this.server.respondWith(/.+/, this.response)
  new PaginatedList(this.el.wrapper, {
    template: this.template,
    url: '/api/v1/test.json'
  })
  this.server.respond()
  this.clock.tick(500)
  equal(this.el.list.children().length, 2)
})

test('should display a view more link if next page is available', function() {
  this.server.respondWith(/.+/, [
    this.response[0],
    {
      'Content-Type': 'application/json',
      Link: 'rel="next"'
    },
    this.response[2]
  ])
  new PaginatedList(this.el.wrapper, {
    template: this.template,
    url: '/api/v1/test.json'
  })
  this.server.respond()
  this.clock.tick(500)
  ok(this.el.wrapper.find('.view-more-link').length > 0)
})

test('should not display a view more link if there is no next page', function() {
  this.server.respondWith(/.+/, this.response)
  new PaginatedList(this.el.wrapper, {
    template: this.template,
    url: '/api/v1/test.json'
  })
  this.server.respond()
  this.clock.tick(500)
  ok(this.el.wrapper.find('.view-more-link').length === 0)
})

test('should accept a template function', function() {
  this.server.respondWith(/.+/, this.response)
  new PaginatedList(this.el.wrapper, {
    template: this.template,
    url: '/api/v1/test.json'
  })
  this.server.respond()
  this.clock.tick(500)
  equal(this.el.list.find('li:first-child').text(), 'one')
  equal(this.el.list.find('li:last-child').text(), 'two')
})

test('should accept a presenter function', function() {
  this.server.respondWith(/.+/, this.response)
  new PaginatedList(this.el.wrapper, {
    presenter: list => list.map(l => ({value: 'changed'})),
    template: this.template,
    url: '/api/v1/test.json'
  })
  this.server.respond()
  this.clock.tick(500)
  equal(this.el.list.find('li:first-child').text(), 'changed')
})

test('should allow user to defer getJSON', function() {
  this.spy($, 'getJSON')
  new PaginatedList(this.el.wrapper, {
    start: false,
    template: this.template,
    url: '/api/v1/not-called.json'
  })
  equal($.getJSON.callCount, 0)
})

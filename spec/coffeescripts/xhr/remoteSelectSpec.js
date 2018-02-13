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
import {keys, groupBy, forEach} from 'lodash'
import RemoteSelect from 'compiled/xhr/RemoteSelect'

QUnit.module('RemoteSelect', {
  setup() {
    this.response = [
      200,
      {'Content-Type': 'application/json'},
      '[{ "label": "one", "value": 1 }, {"label": "two", "value": 2 }]'
    ]
    this.el = $('<select id="test-select"></select>').appendTo('#fixtures')
  },

  teardown() {
    this.el.remove()
    document.getElementById('fixtures').innerHTML = ''
  }
})

test('should load results into a select', function() {
  const server = sinon.fakeServer.create()
  server.respondWith(/.+/, this.response)

  const rs = new RemoteSelect(this.el, {url: '/test/url.json'})
  ok(this.el.prop('disabled'))

  server.respond()
  equal(this.el.children().length, 2)
  server.restore()
})

test('should load an object as <optgroup>', function() {
  this.response.pop()
  this.response.push(
    JSON.stringify({
      'Group One': [{label: 'One', value: 1}, {label: 'Two', value: 2}],
      'Group Two': [{label: 'Three', value: 3}, {label: 'Four', value: 4}]
    })
  )

  const server = sinon.fakeServer.create()
  server.respondWith(/.+/, this.response)

  const rs = new RemoteSelect(this.el, {url: '/test/url.json'})
  server.respond()
  equal(this.el.children('optgroup').length, 2)
  equal(this.el.find('option').length, 4)
  server.restore()
})

test('should cache responses', function() {
  const server = sinon.fakeServer.create()
  server.respondWith(/.+/, this.response)
  this.spy($, 'getJSON')

  const rs = new RemoteSelect(this.el, {url: '/test/cached.json'})
  server.respond()

  ok($.getJSON.calledOnce)
  equal(keys(rs.cache.store).length, 1)
  server.restore()
})

test('should accept a formatter', function() {
  const server = sinon.fakeServer.create()
  this.response.pop()
  this.response.push(
    JSON.stringify([
      {group: 'one', name: 'one', id: 1},
      {group: 'one', name: 'two', id: 2},
      {group: 'two', name: 'three', id: 3},
      {group: 'two', name: 'four', id: 4}
    ])
  )
  server.respondWith(/.+/, this.response)

  function format(data) {
    const groups = groupBy(data, obj => obj.group)
    forEach(
      groups,
      (group, key) => (groups[key] = group.map(item => ({label: item.name, value: item.id})))
    )
    return groups
  }

  const rs = new RemoteSelect(this.el, {
    formatter: format,
    url: '/test/url.json'
  })
  server.respond()

  equal(this.el.children('optgroup').length, 2)
  equal(this.el.find('option').length, 4)
  server.restore()
})

test('should take params', function() {
  const server = sinon.fakeServer.create()
  this.spy($, 'getJSON')

  const rs = new RemoteSelect(this.el, {
    url: '/test/url.json',
    requestParams: {param: 'value'}
  })

  ok($.getJSON.calledWith('/test/url.json', {param: 'value'}, rs.onResponse))
  rs.spinner.remove()
  server.restore()
})

test('should include original options in select', function() {
  const server = sinon.fakeServer.create()
  server.respondWith(/.+/, this.response)
  this.el.append('<option value="">Default</option>')

  const rs = new RemoteSelect(this.el, {url: '/test/url.json'})
  server.respond()

  equal(this.el.children().length, 3)
  server.restore()
})

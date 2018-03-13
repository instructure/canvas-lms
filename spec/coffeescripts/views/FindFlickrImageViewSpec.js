/*
 * Copyright (C) 2013 - present Instructure, Inc.
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
import FindFlickrImageView from 'compiled/views/FindFlickrImageView'
import 'helpers/jquery.simulate'

const searchTerm = 'bunnies'
const photoData = [
  {id: 'noooooo', secret: 'whyyyyy', farm: 'moooo', owner: 'notyou', server: 'maneframe', needs_interstitial: 0},
  {id: 'nooope', secret: 'sobbbbb', farm: 'sadface', owner: 'meeee', server: 'mwhahahah', needs_interstitial: 0},
  {id: 'nsfwid', secret: 'nsfwsecret', farm: 'nsfwfarm', owner: 'nsfwowner', server: 'nsfwserver', needs_interstitial: 1}
]

function setupServerResponses() {
  const server = sinon.fakeServer.create()
  server.respondWith(/\/mock_flickr\/(.*)/, request => {
    const response = {photos: {photo: photoData}}
    if (request.url.indexOf(searchTerm) !== -1) {
      return request.respond(200, {'Content-Type': 'application/json'}, JSON.stringify(response))
    }
  })
  return server
}

QUnit.module('FindFlickrImage', {
  setup() {
    this.server = setupServerResponses()
    const $fixtures = $('#fixtures')
    const view = new FindFlickrImageView()
    view.flickrUrl = '/mock_flickr'
    view.render().$el.appendTo($fixtures)
    this.form = $('form.FindFlickrImageView').first()
  },
  teardown() {
    this.form.remove()
    this.server.restore()
  }
})

test('render', function() {
  expect(6)
  ok(this.form.length, 'flickr - form added to dom')
  ok(this.form.is(':visible'), 'flickr - form is visible')
  const input = $('input.flickrSearchTerm', this.form)
  ok(input.length, 'flickr - search bar is added')
  ok(input.is(':visible'), 'flickr - search bar is visible')
  const button = $('button[type=submit]', this.form)
  ok(button.length, 'flickr - submit button is added')
  ok(button.is(':visible'), 'flickr - submit button form is visible')
})

test('search', function() {
  expect(13)
  const input = $('input.flickrSearchTerm', this.form)
  const button = $('button[type=submit]', this.form)
  input.val(searchTerm)
  this.form.submit()
  this.server.respond()
  const results = $('ul.flickrResults li a.thumbnail', this.form)
  equal(results.length, 2, 'non-nsfw images are added to the results')

  for (let idx = 0; idx <= 1; idx++) {
    ok(results.eq(idx).attr('data-fullsize').includes(photoData[idx].id), 'flickr - img src has id')
    ok(results.eq(idx).attr('data-fullsize').includes(photoData[idx].secret), 'flickr - img src has secret')
    ok(results.eq(idx).attr('data-fullsize').includes(photoData[idx].farm), 'flickr - img src has farm')
    ok(results.eq(idx).attr('data-fullsize').includes(photoData[idx].server), 'flickr - img src has server')
    ok(results.eq(idx).attr('data-linkto').includes(photoData[idx].id), 'flickr - link has id')
    ok(results.eq(idx).attr('data-linkto').includes(photoData[idx].owner), 'flickr - link has owner')
  }
})

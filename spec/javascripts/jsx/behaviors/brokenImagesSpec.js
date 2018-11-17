//
// Copyright (C) 2017 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.
import $ from 'jquery'
import { attachErrorHandler, getImagesAndAttach } from 'compiled/behaviors/broken-images'

let server
QUnit.module('Broken Images Behavior', {
  setup() {
    $('#fixtures').html('<img id="borked" src="broken_image.jpg" alt="broken">')
  },
  teardown() {
    $('#fixtures').empty()
  }
})

test('on error handler attaches the proper class to images when they are broken and not locked', () => {
  server = sinon.fakeServer.create()
  server.respondWith('GET', '/broken_image.jpg', [404, {}, 'Not Found'])
  const $imgElement = $('#borked')
  attachErrorHandler($imgElement)
  $imgElement.triggerHandler('error')
  server.respond()
  ok($imgElement.hasClass('broken-image'))
  server.restore()
})

test('on error handler changes src when the image is locked', () => {
  server = sinon.fakeServer.create()
  server.respondWith('GET', '/broken_image.jpg', [403, {}, 'Forbidden'])
  const $imgElement = $('#borked')
  attachErrorHandler($imgElement)
  $imgElement.triggerHandler('error')
  server.respond()
  equal($imgElement.attr('src'), '/images/svg-icons/icon_lock.svg')
  server.restore()
})

test('on error handler sets appropriate alt text indicating the image is locked', () => {
  server = sinon.fakeServer.create()
  server.respondWith('GET', '/broken_image.jpg', [403, {}, 'Forbidden'])
  const $imgElement = $('#borked')
  attachErrorHandler($imgElement)
  $imgElement.triggerHandler('error')
  server.respond()
  equal($imgElement.attr('alt'), 'Locked image')
  server.restore()
})

QUnit.module('getImagesAndAttach', {
  setup() {
    $('#fixtures').html(
      `<img id="borked" src="broken_image.jpg" alt="broken">
       <img id="empty_src" src alt="empty_src">
      `
    )
  },
  teardown() {
    $('#fixtures').empty()
  }
});

test('does not attach error handler to images with an empty source', () => {
  getImagesAndAttach()
  ok(!$('img#empty_src').data('events'))
})

test('attaches error handler to elements with a non-empty source', () => {
  getImagesAndAttach()
  ok($('img#borked').data('events').error)
})

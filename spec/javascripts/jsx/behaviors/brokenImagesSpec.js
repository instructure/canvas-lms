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
import {setTimeout} from 'timers'

let server
QUnit.module('Broken Images Behavior', {
  setup() {
    $('#fixtures').html('<img id="borked" src="broken_image.jpg" alt="broken">')
  },
  teardown() {
    $('#fixtures').empty()
  }
})

test('on error handler attaches the proper class to images when they are broken and not locked', assert => {
  const done = assert.async()
  const $imgElement = $('#borked')
  attachErrorHandler($imgElement)
  $imgElement.triggerHandler('error')
  setTimeout(() => {
    ok($imgElement.hasClass('broken-image'))
    done()
  }, 100)
})

test('on error handler changes src when the image is locked', assert => {
  const done = assert.async()
  server = sinon.fakeServer.create()
  server.respondWith('GET', '/broken_image.jpg', [403, {}, 'Forbidden'])
  const $imgElement = $('#borked')
  attachErrorHandler($imgElement)
  $imgElement.triggerHandler('error')

  setTimeout(() => {
    server.respond()
    equal($imgElement.attr('src'), '/images/svg-icons/icon_lock.svg')
    server.restore()
    done()
  }, 100)
})

test('on error handler sets appropriate alt text indicating the image is locked', assert => {
  const done = assert.async()
  server = sinon.fakeServer.create()
  server.respondWith('GET', '/broken_image.jpg', [403, {}, 'Forbidden'])
  const $imgElement = $('#borked')
  attachErrorHandler($imgElement)
  $imgElement.triggerHandler('error')
  setTimeout(() => {
    server.respond()
    equal($imgElement.attr('alt'), 'Locked image')
    server.restore()
    done()
  }, 100)
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

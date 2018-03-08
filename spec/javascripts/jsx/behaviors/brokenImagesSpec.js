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
import attachErrorHandler from 'compiled/behaviors/broken-images'

QUnit.module('Broken Images Behavior', {
  setup() {
    $('#fixtures').html('<img id="borked" src="broken_image.jpg">')
  },
  teardown() {
    $('#fixtures').empty()
  }
})

test('on error handler attaches the proper class to images when called', () => {
  const $imgElement = $('#borked')
  attachErrorHandler($imgElement)
  $imgElement.triggerHandler('error')
  ok($imgElement.hasClass('broken-image'))
})

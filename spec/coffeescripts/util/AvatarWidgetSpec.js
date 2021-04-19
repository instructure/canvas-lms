/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import AvatarWidget from '@canvas/avatar-dialog-view'

QUnit.module('AvatarWidget', {
  setup() {},
  teardown() {
    $('.avatar-nav').remove()
    $('.ui-dialog').remove()
    $('#fixtures').empty()
  }
})

test('opens dialog on element click', () => {
  const targetElement = $("<a href='#' id='avatar-opener'>Click</a>")
  $('#fixtures').append(targetElement)
  const wrappedElement = $('a#avatar-opener')
  const widget = new AvatarWidget(wrappedElement)
  wrappedElement.click()
  ok($('.avatar-nav').length > 0)
})

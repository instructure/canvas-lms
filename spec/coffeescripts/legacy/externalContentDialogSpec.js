/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import fakeENV from 'helpers/fakeENV'
import ExternalContentSuccess from 'ui/features/external_content_success/index.js'

QUnit.module('ExternalContentSuccess', {
  setup() {
    window.$ = window.parent.$ = $
    fakeENV.setup({
      service: 'external_tool_redirect'
    })
  },
  teardown() {
    fakeENV.teardown()
    $('#fixtures').html('')
  }
})

test('without iframe should return `undefined` to getIFrameSrc', () => {
  equal(ExternalContentSuccess.getIFrameSrc(), undefined)

  $('#fixtures').html("<span data-cid='Modal'></span>")

  equal(ExternalContentSuccess.getIFrameSrc(), undefined)

  $('#fixtures').html("<span data-cid='Tray'></span>")

  equal(ExternalContentSuccess.getIFrameSrc(), undefined)
})

test('without iframe should return `undefined` to getLaunchType', () => {
  equal(ExternalContentSuccess.getLaunchType(), undefined)

  $('#fixtures').html("<span data-cid='Modal'></span>")

  equal(ExternalContentSuccess.getLaunchType(), undefined)

  $('#fixtures').html("<span data-cid='Tray'></span>")

  equal(ExternalContentSuccess.getLaunchType(), undefined)
})

test('with iframe should return the `src` to getIFrameSrc', () => {
  $('#fixtures').html("<span data-cid='Modal'><iframe src='http://sample.com'></div></span>")

  equal(ExternalContentSuccess.getIFrameSrc(), 'http://sample.com')

  $('#fixtures').html("<span data-cid='Tray'><iframe src='http://sample.com?a=b'></div></span>")

  equal(ExternalContentSuccess.getIFrameSrc(), 'http://sample.com?a=b')
})

test('with iframe should return the `launch_type` to getLaunchType', () => {
  $('#fixtures').html(
    "<span data-cid='Modal'><iframe src='http://sample.com?launch_type=assignment_index_menu'></div></span>"
  )

  equal(ExternalContentSuccess.getLaunchType(), 'assignment_index_menu')

  $('#fixtures').html(
    "<span data-cid='Tray'><iframe src='http://sample.com?launch_type=assignment_index_menu'></div></span>"
  )

  equal(ExternalContentSuccess.getLaunchType(), 'assignment_index_menu')
})

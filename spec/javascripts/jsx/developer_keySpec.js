/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import 'compiled/handlebars_helpers'
import developerKey from 'jst/developer_key'
import $ from 'jquery'
import 'jquery.instructure_date_and_time'

test('renders nothing in the notes field when the value is NULL', () => {
  const data = {
    icon_image_url: '/images/blank.png',
    name: 'Test',
    user_name: 'Test User',
    created: $.datetimeString('2017-05-18 22:19:41.358852'),
    last_auth: $.datetimeString('2017-05-18 22:19:41.358852'),
    last_access: $.datetimeString('2017-05-18 22:19:41.358852'),
    inactive: false,
    notes: null
  }
  const $key = $(developerKey(data))
  equal($key.find('.notes').children().length, 0)
})

test('renders nothing in the notes field when the value is an empty string', () => {
  const data = {
    icon_image_url: '/images/blank.png',
    name: 'Test',
    user_name: 'Test User',
    created: $.datetimeString('2017-05-18 22:19:41.358852'),
    last_auth: $.datetimeString('2017-05-18 22:19:41.358852'),
    last_access: $.datetimeString('2017-05-18 22:19:41.358852'),
    inactive: false,
    notes: ''
  }
  const $key = $(developerKey(data))
  equal($key.find('.notes').children().length, 0)
})

test('shows the note in the notes field when one exists', () => {
  const data = {
    icon_image_url: '/images/blank.png',
    name: 'Test',
    user_name: 'Test User',
    created: $.datetimeString('2017-05-18 22:19:41.358852'),
    last_auth: $.datetimeString('2017-05-18 22:19:41.358852'),
    last_access: $.datetimeString('2017-05-18 22:19:41.358852'),
    inactive: false,
    notes: 'I am a note'
  }
  const $key = $(developerKey(data))
  ok(
    $key
      .find('.notes')
      .text()
      .match(/I am a note/)
  )
})

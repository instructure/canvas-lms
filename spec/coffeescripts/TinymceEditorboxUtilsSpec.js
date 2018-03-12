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

import {cleanUrl} from 'tinymce.editor_box_utils'

QUnit.module('Tinymce Utils #cleanUrl')

test('it doesnt hurt a good url', () => {
  const url = 'http://www.google.com'
  const output = cleanUrl(url)
  equal(output, url)
})

test('it turns email addresses into mailto links', () => {
  const output = cleanUrl('ethan@instructure.com')
  equal(output, 'mailto:ethan@instructure.com')
})

test('adding a protocol to unprotocoled addresses', () => {
  const input = 'www.example.com'
  const output = cleanUrl(input)
  equal(output, `http://${input}`)
})

test('doesnt mailto links with @ in them', () => {
  const input =
    'https://www.google.com/maps/place/331+E+Winchester+St,+Murray,+UT+84107/@40.633021,-111.880836,17z/data=!3m1!4b1!4m2!3m1!1s0x875289b8a03ae74d:0x2e83de307059e47d'
  const output = cleanUrl(input)
  equal(output, input)
})

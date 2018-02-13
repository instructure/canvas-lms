/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import NotificationPreferences from 'compiled/notifications/NotificationPreferences'

QUnit.module('NotificationPreferences')

test('tooltip instance was added', () => {
  const options = {update_url: '/profile/communication_update'}
  const nps = new NotificationPreferences(options)
  const $np = $('#notification-preferences')
  const freq = $np.find('.frequency')
  const inst = $(freq).tooltip('instance')
  notEqual(inst, undefined)
})

test('policyCellProps with email', () => {
  const options = {update_url: '/profile/communication_update'}
  const nps = new NotificationPreferences(options)
  const category = {category: 'helloworld'}
  const channel = {
    type: 'email',
    id: 42
  }
  const props = nps.policyCellProps(category, channel)
  equal(props.buttonData.length, 4)
})

test('policyCellProps with sms', () => {
  const options = {update_url: '/profile/communication_update'}
  const nps = new NotificationPreferences(options)
  const category = {category: 'helloworld'}
  const channel = {
    type: 'sms',
    id: 42
  }
  const props = nps.policyCellProps(category, channel)
  equal(props.buttonData.length, 2)
})

test('policyCellProps with twitter', () => {
  const options = {update_url: '/profile/communication_update'}
  const nps = new NotificationPreferences(options)
  const category = {category: 'helloworld'}
  const channel = {
    type: 'twitter',
    id: 42
  }
  const props = nps.policyCellProps(category, channel)
  equal(props.buttonData.length, 2)
})

test('policyCellProps with sms', () => {
  const options = {update_url: '/profile/communication_update'}
  const nps = new NotificationPreferences(options)
  const category = {category: 'helloworld'}
  const channel = {
    type: 'sms',
    id: 42
  }
  const props = nps.policyCellProps(category, channel)
  equal(props.buttonData.length, 2)
})

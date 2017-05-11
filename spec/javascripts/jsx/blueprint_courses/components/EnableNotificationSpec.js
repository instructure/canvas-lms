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

import React from 'react'
import * as enzyme from 'enzyme'
import EnableNotification from 'jsx/blueprint_courses/components/EnableNotification'
import MigrationStates from 'jsx/blueprint_courses/migrationStates'

const noop = () => {}

QUnit.module('EnableNotification component')

const defaultProps = {
  migrationStatus: MigrationStates.states.unknown,
  willSendNotification: false,
  willIncludeCustomNotificationMessage: false,
  notificationMessage: '',
  enableSendNotification: noop,
  includeCustomNotificationMessage: noop,
  setNotificationMessage: noop,
}

test('renders the EnableNotification component', () => {
  const tree = enzyme.shallow(<EnableNotification {...defaultProps} />)
  const node = tree.find('.bcs__history-notification')
  ok(node.exists())
})

test('renders the enable checkbox', () => {
  const tree = enzyme.mount(<EnableNotification {...defaultProps} />)
  const checkboxes = tree.find('input[type="checkbox"]')
  equal(checkboxes.length, 1)
  equal(checkboxes.node.checked, false)
})

test('renders the add a message checkbox', () => {
  const props = {...defaultProps}
  props.willSendNotification = true

  const tree = enzyme.mount(<EnableNotification {...props} />)
  const checkboxes = tree.find('Checkbox')
  equal(checkboxes.length, 2)
  equal(checkboxes.get(0).checked, true)
  equal(checkboxes.get(1).checked, false)
  const messagebox = tree.find('TextArea')
  ok(!messagebox.exists())
})

test('renders the message text area', () => {
  const props = {...defaultProps}
  props.willSendNotification = true
  props.willIncludeCustomNotificationMessage = true

  const tree = enzyme.mount(<EnableNotification {...props} />)
  const checkboxes = tree.find('Checkbox')
  equal(checkboxes.length, 2)
  equal(checkboxes.get(0).checked, true)
  equal(checkboxes.get(1).checked, true)
  const messagebox = tree.find('TextArea')
  ok(messagebox.exists())
})

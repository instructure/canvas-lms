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
import MigrationOptions from 'ui/features/blueprint_course_master/react/components/MigrationOptions'
import MigrationStates from '@canvas/blueprint-courses/react/migrationStates'

const noop = () => {}

QUnit.module('MigrationOptions component')

const defaultProps = {
  migrationStatus: MigrationStates.states.unknown,
  willSendNotification: false,
  willIncludeCustomNotificationMessage: false,
  willIncludeCourseSettings: false,
  notificationMessage: '',
  enableSendNotification: noop,
  includeCustomNotificationMessage: noop,
  setNotificationMessage: noop,
  includeCourseSettings: noop,
}

test('renders the MigrationOptions component', () => {
  const tree = enzyme.shallow(<MigrationOptions {...defaultProps} />)
  const node = tree.find({as: 'fieldset'})
  ok(node.exists())
})

test('renders the course-settings and notification-enable checkboxes', () => {
  const tree = enzyme.mount(<MigrationOptions {...defaultProps} />)
  const checkboxes = tree.find('input[type="checkbox"]')
  equal(checkboxes.length, 2)
  equal(checkboxes.at(0).prop('checked'), false)
  equal(checkboxes.at(1).prop('checked'), false)
})

test('renders the add a message checkbox', () => {
  const props = {...defaultProps}
  props.willSendNotification = true

  const tree = enzyme.mount(<MigrationOptions {...props} />)

  ok(tree.find('Checkbox[label="Include Course Settings"]').first().exists())
  equal(tree.find('Checkbox[label="Include Course Settings"]').first().prop('checked'), false)

  ok(tree.find('Checkbox[label="Send Notification"]').first().exists())
  equal(tree.find('Checkbox[label="Send Notification"]').first().prop('checked'), true)

  const checkbox3 = tree
    .find('Checkbox')
    .filterWhere(n => n.text().includes('0/140'))
    .first()
  ok(checkbox3.exists())
  equal(checkbox3.prop('checked'), false)

  const messagebox = tree.find('TextArea')
  ok(!messagebox.exists())
})

test('renders the message text area', () => {
  const props = {...defaultProps}
  props.willSendNotification = true
  props.willIncludeCustomNotificationMessage = true

  const tree = enzyme.mount(<MigrationOptions {...props} />)
  const messagebox = tree.find('TextArea')
  ok(messagebox.exists())
})

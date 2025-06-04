/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {render} from '@testing-library/react'
import MigrationOptions from '../MigrationOptions'
import MigrationStates from '@canvas/blueprint-courses/react/migrationStates'

const noop = () => {}

describe('MigrationOptions component', () => {
  const defaultProps = {
    migrationStatus: MigrationStates.states.unknown,
    willSendNotification: false,
    willIncludeCustomNotificationMessage: false,
    willIncludeCourseSettings: false,
    notificationMessage: '',
    willSendItemNotifications: false,
    itemNotificationFeatureEnabled: false,
    enableSendNotification: noop,
    includeCustomNotificationMessage: noop,
    setNotificationMessage: noop,
    includeCourseSettings: noop,
    enableItemNotifications: noop,
  }

  test('renders the MigrationOptions component', () => {
    const {container} = render(<MigrationOptions {...defaultProps} />)
    const node = container.querySelector('fieldset')
    expect(node).toBeTruthy()
  })

  test('renders the course-settings and notification-enable checkboxes', () => {
    const {container} = render(<MigrationOptions {...defaultProps} />)
    const checkboxes = container.querySelectorAll('input[type="checkbox"]')
    expect(checkboxes).toHaveLength(2)
    expect(checkboxes[0].checked).toEqual(false)
    expect(checkboxes[1].checked).toEqual(false)
  })

  test('renders the item-notifications checkbox if the feature is enabled', () => {
    const props = {...defaultProps}
    props.itemNotificationFeatureEnabled = true
    const {container} = render(<MigrationOptions {...props} />)
    const checkboxes = container.querySelectorAll('input[type="checkbox"]')
    expect(checkboxes).toHaveLength(3)
    expect(checkboxes[2].checked).toEqual(false)
  })

  test('renders the add a message checkbox', () => {
    const props = {...defaultProps}
    props.willSendNotification = true

    const {container, getByLabelText} = render(<MigrationOptions {...props} />)

    const courseSettingsCheckbox = getByLabelText('Include Course Settings')
    expect(courseSettingsCheckbox).toBeTruthy()
    expect(courseSettingsCheckbox.checked).toEqual(false)

    const notificationCheckbox = getByLabelText('Send Notification')
    expect(notificationCheckbox).toBeTruthy()
    expect(notificationCheckbox.checked).toEqual(true)

    const checkbox3 = getByLabelText('Add a Message (0/140)')
    expect(checkbox3).toBeTruthy()
    expect(checkbox3.checked).toEqual(false)

    const messagebox = container.querySelector('textarea')
    expect(messagebox).toBeFalsy()
  })

  test('renders the message text area', () => {
    const props = {...defaultProps}
    props.willSendNotification = true
    props.willIncludeCustomNotificationMessage = true

    const {container} = render(<MigrationOptions {...props} />)
    const messagebox = container.querySelector('textarea')
    expect(messagebox).toBeTruthy()
  })
})

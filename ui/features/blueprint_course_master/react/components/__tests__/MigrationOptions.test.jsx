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
import {shallow} from 'enzyme'
import {render} from '@testing-library/react'
import {getByLabelText} from '@testing-library/dom'
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
    enableSendNotification: noop,
    includeCustomNotificationMessage: noop,
    setNotificationMessage: noop,
    includeCourseSettings: noop,
  }

  test('renders the MigrationOptions component', () => {
    const tree = shallow(<MigrationOptions {...defaultProps} />)
    const node = tree.find({as: 'fieldset'})
    expect(node.exists()).toBeTruthy()
  })

  test('renders the course-settings and notification-enable checkboxes', () => {
    const tree = render(<MigrationOptions {...defaultProps} />)
    const checkboxes = tree.container.querySelectorAll('input[type="checkbox"]')
    expect(checkboxes.length).toEqual(2)
    expect(checkboxes[0].checked).toEqual(false)
    expect(checkboxes[1].checked).toEqual(false)
  })

  test('renders the add a message checkbox', () => {
    const props = {...defaultProps}
    props.willSendNotification = true

    const tree = render(<MigrationOptions {...props} />)

    const courseSettingsCheckbox = getByLabelText(tree.container, 'Include Course Settings')
    expect(courseSettingsCheckbox).toBeTruthy()
    expect(courseSettingsCheckbox.checked).toEqual(false)

    const notificationCheckbox = getByLabelText(tree.container, 'Send Notification')
    expect(notificationCheckbox).toBeTruthy()
    expect(notificationCheckbox.checked).toEqual(true)

    const checkbox3 = getByLabelText(tree.container, 'Add a Message (0/140)')
    expect(checkbox3).toBeTruthy()
    expect(checkbox3.checked).toEqual(false)

    const messagebox = tree.container.querySelector('textarea')
    expect(messagebox).toBeFalsy()
  })

  test('renders the message text area', () => {
    const props = {...defaultProps}
    props.willSendNotification = true
    props.willIncludeCustomNotificationMessage = true

    const tree = render(<MigrationOptions {...props} />)
    const messagebox = tree.container.querySelector('textarea')
    expect(messagebox).toBeTruthy()
  })
})

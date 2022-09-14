/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {fireEvent, render} from '@testing-library/react'
import BBBModalOptions from '../BBBModalOptions'

describe('BBBModalOptions', () => {
  const setName = jest.fn()
  const setDuration = jest.fn()
  const setOptions = jest.fn()
  const setDescription = jest.fn()
  const setInvitationOptions = jest.fn()
  const setAttendeesOptions = jest.fn()

  const defaultProps = {
    name: 'Conference 1',
    setName,
    duration: 46,
    setDuration,
    options: ['recording_enabled', 'no_time_limit', 'enable_waiting_room'],
    setOptions,
    description: 'First conference of all time',
    setDescription,
    invitationOptions: ['invite_all'],
    setInvitationOptions,
    attendeesOptions: [
      'share_webcam',
      'share_other_webcams',
      'share_microphone',
      'send_public_chat',
      'send_private_chat'
    ],
    setAttendeesOptions
  }

  const setup = (props = {}) => {
    return render(
      <BBBModalOptions
        name={props.name}
        onSetName={props.setName}
        duration={props.duration}
        onSetDuration={props.setDuration}
        options={props.options}
        onSetOptions={props.setOptions}
        description={props.description}
        onSetDescription={props.setDescription}
        invitationOptions={props.invitationOptions}
        onSetInvitationOptions={props.setInvitationOptions}
        attendeesOptions={props.attendeesOptions}
        onSetAttendeesOptions={props.setAttendeesOptions}
        showCalendar={props.showCalendar}
        startDate={props.startDate}
        endDate={props.endDate}
      />
    )
  }

  beforeEach(() => {
    setName.mockClear()
    setDuration.mockClear()
    setOptions.mockClear()
    setDescription.mockClear()
    setInvitationOptions.mockClear()
    setAttendeesOptions.mockClear()

    window.ENV.bbb_recording_enabled = true
  })

  it('should render', () => {
    const container = setup(defaultProps)
    expect(container).toBeTruthy()
  })

  it('should render with default props', () => {
    const container = setup(defaultProps)
    expect(container.getByLabelText('Name')).toHaveValue(defaultProps.name)
    expect(container.getByLabelText('Duration in Minutes')).toHaveValue('')
    expect(container.getByLabelText('Enable recording for this conference').checked).toBeTruthy()
    expect(container.getByLabelText('Enable recording for this conference').disabled).toBeFalsy()
    expect(container.getByLabelText('Description')).toHaveValue(defaultProps.description)

    fireEvent.click(container.getByText('Attendees'))
    expect(container.getByLabelText('Share webcam').checked).toBeTruthy()
  })

  it('it should set default calendar dates when provided', () => {
    const customProps = defaultProps
    customProps.showCalendar = true
    const container = setup(customProps)

    const startInput = container.getByLabelText('Start Date')
    const endInput = container.getByLabelText('End Date')

    expect(startInput).toBeTruthy()
    expect(endInput).toBeTruthy()
  })

  it('it should not render calendar when prop is false', () => {
    const customProps = defaultProps
    customProps.showCalendar = false
    const container = setup(customProps)

    const startInput = container.queryByLabelText('Start Date')
    const endInput = container.queryByLabelText('End Date')

    expect(startInput).toBeFalsy()
    expect(endInput).toBeFalsy()
  })

  it('should disable recording if setting is disabled', () => {
    window.ENV.bbb_recording_enabled = false
    const container = setup(defaultProps)
    expect(container.getByLabelText('Enable recording for this conference').disabled).toBeTruthy()
  })
})

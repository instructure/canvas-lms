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
import {render} from '@testing-library/react'
import BBBModalOptions from '../BBBModalOptions'
import {SETTINGS_TAB, ATTENDEES_TAB} from '../../../../util/constants'

describe('BBBModalOptions', () => {
  const setName = jest.fn()
  const setDuration = jest.fn()
  const setOptions = jest.fn()
  const setDescription = jest.fn()
  const setInvitationOptions = jest.fn()
  const setAttendeesOptions = jest.fn()
  const setAddToCalendar = jest.fn()

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
      'send_private_chat',
    ],
    setAttendeesOptions,
    setAddToCalendar,
    addToCalendar: false,
    tab: SETTINGS_TAB,
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
        setAddToCalendar={props.setAddToCalendar}
        addToCalendar={props.addToCalendar}
        tab={props.tab}
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
    const {getByLabelText, getAllByLabelText} = setup(defaultProps)
    expect(getByLabelText('Name')).toHaveValue(defaultProps.name)
    expect(getAllByLabelText('Duration in Minutes')[0]).toHaveValue('')
    expect(getByLabelText('Enable recording for this conference').checked).toBeTruthy()
    expect(getByLabelText('Enable recording for this conference').disabled).toBeFalsy()
    expect(getByLabelText('Description')).toHaveValue(defaultProps.description)
  })

  it('should render attendees tab', () => {
    const container = setup({...defaultProps, tab: ATTENDEES_TAB})
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

  it('should lock Invitation Options & set inviteAll equal to true if add_to_calendar is checked', () => {
    const customProps = defaultProps
    customProps.options.push('add_to_calendar')
    customProps.addToCalendar = true

    const container = setup({...customProps, tab: ATTENDEES_TAB})
    expect(container.getByLabelText('Invite all course members').checked).toBeTruthy()
    expect(container.getByLabelText('Invite all course members').disabled).toBeTruthy()
    expect(container.getByLabelText('Remove all course observer members').disabled).toBeTruthy()
    expect(container.getByLabelText('Remove all course observer members').checked).toBeFalsy()
    expect(container.getAllByTestId('inviteAll-tooltip')).toBeTruthy()
  })

  it('should lock Remove Observers if Invite All is not checked', () => {
    const customProps = defaultProps
    customProps.invitationOption = []

    const container = setup({...customProps, tab: ATTENDEES_TAB})
    expect(container.getByLabelText('Remove all course observer members').disabled).toBeTruthy()
  })

  it('does not show add to calendar when context is group', () => {
    window.ENV.context_asset_string = 'group_1'
    const customProps = defaultProps
    const container = setup({...customProps})

    expect(container.queryByText('Add to Calendar')).not.toBeInTheDocument()
  })

  it('shows add to calendar when context and can_manage_calendar', () => {
    window.ENV.context_asset_string = 'course_1'
    window.ENV.can_manage_calendar = true
    const customProps = defaultProps
    const container = setup({...customProps})
    expect(container.queryByText('Add to Calendar')).toBeInTheDocument()
  })
})

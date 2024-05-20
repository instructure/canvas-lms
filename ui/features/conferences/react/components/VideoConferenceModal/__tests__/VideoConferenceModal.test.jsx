// @vitest-environment jsdom
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
import {VideoConferenceModal} from '../VideoConferenceModal'
import userEvent from '@testing-library/user-event'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'

injectGlobalAlertContainers()

const userList = [
  {displayName: 'Allison Pitler', id: '7', assetCode: '7'},
  {displayName: 'Caleb Guanzon', id: '3', assetCode: '3'},
  {displayName: 'Chawn Neal', id: '2', assetCode: '2'},
  {displayName: 'Drake Harper', id: '1', assetCode: '1'},
  {displayName: 'Jason Gillet', id: '5', assetCode: '5'},
  {displayName: 'Jeffrey Johnson', id: '0', assetCode: '0'},
  {displayName: 'Jewel Pearson', id: '8', assetCode: '8'},
  {displayName: 'Nic Nolan', id: '6', assetCode: '6'},
  {displayName: 'Omar Soto Fortuno', id: '4', assetCode: '4'},
]

const startCalendarDate = new Date().toISOString()
const endCalendarDate = new Date().toISOString()

describe('VideoConferenceModal', () => {
  const onDismiss = jest.fn()
  const onSubmit = jest.fn()
  let originalEnv

  const setup = (props = {}) => {
    return render(
      <VideoConferenceModal
        open={true}
        availableAttendeesList={userList}
        onDismiss={onDismiss}
        onSubmit={onSubmit}
        startCalendarDate={startCalendarDate}
        endCalendarDate={endCalendarDate}
        {...props}
      />
    )
  }

  beforeEach(() => {
    originalEnv = JSON.parse(JSON.stringify(window.ENV))
    onDismiss.mockClear()
    onSubmit.mockClear()
    window.ENV.conference_type_details = [
      {
        name: 'BigBlueButton',
        type: 'BigBlueButton',
        settings: [],
        free_trial: false,
        send_avatar: false,
        lti_settings: null,
        contexts: null,
      },
    ]
    window.ENV.bbb_recording_enabled = true
    window.ENV.context_name = 'Amazing Course'
  })

  afterEach(() => {
    window.ENV = originalEnv
  })

  it('should render', () => {
    const container = setup()
    expect(container).toBeTruthy()
  })

  it('call onDismiss when clicking the cancel button', () => {
    const container = setup()

    fireEvent.click(container.getByTestId('cancel-button'))
    expect(onDismiss).toHaveBeenCalled()
  })

  it('do not submit without a conference name', async () => {
    const container = setup()
    expect(container.getByLabelText('Name')).toHaveValue('Amazing Course Conference')
    await userEvent.clear(container.getByLabelText('Name'))
    fireEvent.click(container.getByTestId('submit-button'))
    expect(onSubmit).not.toHaveBeenCalled()
  })

  it.skip('submit when correct fields are filled (flaky)', async () => {
    const container = setup()

    await userEvent.clear(container.getByLabelText('Name'))
    await userEvent.type(container.getByLabelText('Name'), 'A great video conference name')
    await userEvent.type(
      container.getByLabelText('Description'),
      'A great video conference description'
    )
    await userEvent.click(container.getByTestId('submit-button'))

    expect(onSubmit).toHaveBeenCalled()
    expect(onSubmit.mock.calls[0][1]).toStrictEqual({
      name: 'A great video conference name',
      duration: 60,
      options: ['recording_enabled'],
      conferenceType: 'BigBlueButton',
      description: 'A great video conference description',
      invitationOptions: ['invite_all'],
      attendeesOptions: [
        'share_webcam',
        'share_other_webcams',
        'share_microphone',
        'send_public_chat',
        'send_private_chat',
      ],
      selectedAttendees: [],
      startCalendarDate,
      endCalendarDate,
    })
  })

  it('duration input arrows should work appropriately.', () => {
    const container = setup()
    const durationInput = container.getByTestId('duration-input')
    const arrowUpButton = durationInput
      .querySelector("svg[name='IconArrowOpenUp']")
      .closest('button')
    const arrowDownButton = durationInput
      .querySelector("svg[name='IconArrowOpenDown']")
      .closest('button')

    expect(container.getByLabelText('Duration in Minutes')).toHaveValue('60')

    fireEvent.mouseDown(arrowUpButton)
    fireEvent.mouseDown(arrowUpButton)
    expect(container.getByLabelText('Duration in Minutes')).toHaveValue('62')

    fireEvent.mouseDown(arrowDownButton)
    expect(container.getByLabelText('Duration in Minutes')).toHaveValue('61')
  })

  it('shows attendees tab after clicking it', () => {
    const container = setup()

    fireEvent.click(container.getByText('Attendees'))
    expect(container.getByText('Invite all course members')).toBeInTheDocument()
    expect(container.getByText('Remove all course observer members')).toBeInTheDocument()
  })

  it('shows correct group options in attendees tab', () => {
    window.ENV.context_asset_string = 'group_1'
    const container = setup()

    fireEvent.click(container.getByText('Attendees'))
    expect(container.getByText('Invite all group members')).toBeInTheDocument()
    expect(container.queryByText('Remove all course observer members')).not.toBeInTheDocument()
  })

  it('shows New Video Conference and Create button when not on editing mode', () => {
    const container = setup()

    expect(container.getByText('New Video Conference')).toBeInTheDocument()
    expect(container.getByText('Create')).toBeInTheDocument()
  })

  it('display correct values provided as props on editing mode', () => {
    const container = setup({
      isEditing: true,
      name: 'PHP Introduction',
      duration: 45,
      options: ['recording_enabled'],
      description: 'An introduction to PHP.',
      invitationOptions: [],
      attendeesOptions: ['share_webcam'],
      type: 'BigBlueButton',
    })

    expect(container.getByText('Save')).toBeInTheDocument()
    expect(container.getByText('Edit Video Conference')).toBeInTheDocument()
    expect(container.getByLabelText('Name')).toHaveValue('PHP Introduction')
    expect(container.getByLabelText('Duration in Minutes')).toHaveValue('45')
    expect(container.getByLabelText('Enable recording for this conference').checked).toBeTruthy()
    expect(container.getByLabelText('Description')).toHaveValue('An introduction to PHP.')

    fireEvent.click(container.getByText('Attendees'))
    expect(container.getByLabelText('Share webcam').checked).toBeTruthy()
  })

  it('doesnt call onSubmit when there is an error and you are on the Attendees tab', () => {
    const container = setup({
      isEditing: true,
      name: '',
      duration: 45,
      options: ['recording_enabled'],
      description: '',
      invitationOptions: [],
      attendeesOptions: ['share_webcam'],
      type: 'BigBlueButton',
    })

    fireEvent.click(container.getByText('Attendees'))
    fireEvent.click(container.getByTestId('submit-button'))

    expect(onSubmit).not.toHaveBeenCalled()
  })
})

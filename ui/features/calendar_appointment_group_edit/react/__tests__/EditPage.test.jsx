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

import $ from 'jquery'
import React from 'react'
import {render, waitFor, fireEvent, screen as testScreen} from '@testing-library/react'
import EditPage from '../EditPage'
import axios from '@canvas/axios'
import MessageParticipantsDialog from '@canvas/calendar/jquery/MessageParticipantsDialog'
import {assignLocation} from '@canvas/util/globalUtils'

jest.mock('@canvas/axios')
jest.mock('@canvas/calendar/jquery/MessageParticipantsDialog')
jest.mock('@canvas/util/globalUtils', () => ({
  assignLocation: jest.fn(),
}))

// Mock jQuery dialog and form methods
$.fn.dialog = jest.fn()
$.fn.errorBox = jest.fn()
$.fn.getClientRects = () => [{top: 0, left: 0}]
$.fn.offset = () => ({top: 0, left: 0})
$.fn.position = () => ({top: 0, left: 0})
$.fn.val = jest.fn().mockReturnValue('')
$.flashError = jest.fn()

const defaultProps = {
  appointment_group_id: '1',
}

const mockAppointmentGroup = {
  id: '1',
  title: 'Test Group',
  description: 'Test Description',
  location_name: 'Test Location',
  participants_per_appointment: 1,
  participant_visibility: 'private',
  max_appointments_per_participant: 1,
  context_codes: ['course_1'],
  sub_context_codes: [],
  workflow_state: 'active',
  requiring_action: false,
  appointments_count: 0,
  user_color: null,
  context_color: null,
  appointments: [],
}

const mockContexts = {
  contexts: [
    {
      asset_string: 'course_1',
      name: 'Test Course',
      allow_observers_in_appointment_groups: true,
    },
  ],
}

describe('AppointmentGroup EditPage', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    MessageParticipantsDialog.mockImplementation(function () {
      return {
        show: jest.fn(),
      }
    })
    axios.get.mockImplementation(url => {
      if (url.includes('appointment_groups')) {
        return Promise.resolve({data: mockAppointmentGroup})
      }
      if (url.includes('calendar_events')) {
        return Promise.resolve({data: mockContexts})
      }
      return Promise.reject(new Error('Unknown URL'))
    })
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders the EditPage component', async () => {
    render(<EditPage {...defaultProps} />)
    await waitFor(() => {
      expect(testScreen.getByTestId('edit-page')).toBeInTheDocument()
    })
  })

  describe('API Interactions', () => {
    it('fetches appointment group data', async () => {
      render(<EditPage {...defaultProps} />)
      await waitFor(() => {
        expect(axios.get).toHaveBeenCalledWith(
          '/api/v1/appointment_groups/1?include[]=appointments&include[]=child_events',
        )
      })
    })

    it('fetches calendar events data', async () => {
      render(<EditPage {...defaultProps} />)
      await waitFor(() => {
        expect(axios.get).toHaveBeenCalledWith('/api/v1/calendar_events/visible_contexts')
      })
    })
  })

  describe('Message Users', () => {
    it('renders message users button', async () => {
      render(<EditPage {...defaultProps} />)
      await waitFor(() => {
        expect(testScreen.getByText('Message Students')).toBeInTheDocument()
      })
    })

    it('opens message students modal when clicking button', async () => {
      render(<EditPage {...defaultProps} />)
      await waitFor(() => {
        const messageButton = testScreen.getByText('Message Students')
        fireEvent.click(messageButton)
        expect(MessageParticipantsDialog).toHaveBeenCalledWith({
          group: expect.any(Object),
          dataSource: expect.any(Object),
        })
      })
    })
  })

  describe('Delete Group', () => {
    it('sends delete request with correct id and redirects', async () => {
      axios.delete.mockResolvedValueOnce({})
      render(<EditPage {...defaultProps} />)
      const deleteButton = await testScreen.findByText('Delete Group')
      fireEvent.click(deleteButton)
      await waitFor(() => {
        expect(axios.delete).toHaveBeenCalledWith('/api/v1/appointment_groups/1')
        expect(assignLocation).toHaveBeenCalledWith('/calendar')
      })
    })

    it('shows error message on failed delete', async () => {
      axios.delete.mockRejectedValueOnce(new Error('Failed to delete'))
      render(<EditPage {...defaultProps} />)
      const deleteButton = await testScreen.findByText('Delete Group')
      fireEvent.click(deleteButton)
      await waitFor(() => {
        expect($.flashError).toHaveBeenCalledWith(
          'An error occurred while deleting the appointment group',
        )
      })
    })
  })

  describe('Form Interactions', () => {
    it('updates form values on input change', async () => {
      render(<EditPage {...defaultProps} />)
      const titleInput = await testScreen.findByRole('textbox', {name: 'Title'})
      fireEvent.change(titleInput, {target: {value: 'New Title', name: 'title'}})
      expect(titleInput.value).toBe('New Title')
    })

    it('updates checkbox values correctly', async () => {
      render(<EditPage {...defaultProps} />)
      const checkbox = await testScreen.findByRole('checkbox', {
        name: 'Allow students to see who was signed up for time slots that are still available',
      })
      fireEvent.click(checkbox)
      expect(checkbox).toBeChecked()
    })
  })

  describe('Save Group', () => {
    beforeEach(() => {
      axios.put.mockResolvedValue({})
    })

    it('shows error for empty limit users per slot', async () => {
      const {container} = render(<EditPage {...defaultProps} />)

      // Click the checkbox to enable the input
      const checkbox = container.querySelector('#limit_users_per_slot')
      fireEvent.click(checkbox)

      // Mock the jQuery val() call to return an empty string
      $.fn.val.mockReturnValue('')

      // Click save to trigger validation
      const saveButton = testScreen.getByText('Save')
      fireEvent.click(saveButton)

      await waitFor(() => {
        expect($.fn.errorBox).toHaveBeenCalledWith(
          'You must provide a value or unselect the option.',
        )
      })
    })

    it('shows error for invalid limit users per slot', async () => {
      const {container} = render(<EditPage {...defaultProps} />)

      // Click the checkbox to enable the input
      const checkbox = container.querySelector('#limit_users_per_slot')
      fireEvent.click(checkbox)

      // Set and trigger change on the input
      const input = container.querySelector('.EditPage__Options-LimitUsersPerSlot')
      Object.defineProperty(input, 'value', {value: '0'})
      fireEvent.change(input, {target: {value: '0'}})

      // Mock the jQuery val() call to return 0
      $.fn.val = jest.fn().mockReturnValue('0')

      const saveButton = testScreen.getByText('Save')
      fireEvent.click(saveButton)

      await waitFor(() => {
        expect($.fn.errorBox).toHaveBeenCalledWith(
          'You must allow at least one appointment per time slot.',
        )
      })
    })

    it('prepares correct participant visibility', async () => {
      const {container} = render(<EditPage {...defaultProps} />)

      // Set the "Allow students to see who was signed up" checkbox
      const visibilityCheckbox = container.querySelector('input[name="allowStudentsToView"]')
      fireEvent.click(visibilityCheckbox)

      // Set the "Limit users per time slot" checkbox and input
      const limitUsersCheckbox = container.querySelector('#limit_users_per_slot')
      fireEvent.click(limitUsersCheckbox)
      const input = container.querySelector('.EditPage__Options-LimitUsersPerSlot')

      // Set both the value and usersPerSlotLimit
      Object.defineProperty(input, 'value', {value: '1'})
      fireEvent.change(input, {target: {name: 'limitUsersPerSlot', value: '1'}})

      // Mock the jQuery val() call to return 1
      $.fn.val = jest.fn().mockReturnValue('1')

      const saveButton = testScreen.getByText('Save')
      fireEvent.click(saveButton)

      await waitFor(() => {
        expect(axios.put).toHaveBeenCalledWith(
          '/api/v1/appointment_groups/1',
          expect.objectContaining({
            appointment_group: expect.objectContaining({
              participant_visibility: 'protected',
              participants_per_appointment: '1',
            }),
          }),
        )
      })
    })

    it('shows error on failed save', async () => {
      axios.put.mockRejectedValueOnce(new Error('Failed to save'))
      render(<EditPage {...defaultProps} />)
      const saveButton = testScreen.getByText('Save')
      fireEvent.click(saveButton)
      await waitFor(() => {
        expect($.flashError).toHaveBeenCalledWith(
          'An error occurred while saving the appointment group',
        )
      })
    })

    it('redirects to calendar on successful save', async () => {
      axios.put.mockResolvedValueOnce({})
      render(<EditPage {...defaultProps} />)
      const saveButton = testScreen.getByText('Save')
      fireEvent.click(saveButton)
      await waitFor(() => {
        expect(assignLocation).toHaveBeenCalledWith('/calendar?edit_appointment_group_success=1')
      })
    })
  })
})

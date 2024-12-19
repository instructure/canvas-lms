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
import {render, screen} from '@testing-library/react'
import AppointmentGroupList from '../AppointmentGroupList'

const mockAppointmentGroup = {
  appointments: [
    {
      id: '1',
      start_at: '2024-04-01T10:00:00Z',
      end_at: '2024-04-01T11:00:00Z',
      child_events: [],
    },
    {
      id: '2',
      start_at: '2024-04-02T12:00:00Z',
      end_at: '2024-04-02T13:00:00Z',
      child_events: [{user: {sortable_name: 'John Doe'}}],
    },
  ],
  participants_per_appointment: 2,
}

describe('AppointmentGroupList', () => {
  test('renders a list of appointments', () => {
    render(<AppointmentGroupList appointmentGroup={mockAppointmentGroup} />)
    const appointments = screen.getAllByText(/to/)
    expect(appointments).toHaveLength(2)
  })

  test('displays "Available" for unreserved appointments', () => {
    render(<AppointmentGroupList appointmentGroup={mockAppointmentGroup} />)
    const availableBadge = screen.getByText('Available')
    expect(availableBadge).toBeInTheDocument()
  })

  test('displays "Reserved" for reserved appointments', () => {
    render(<AppointmentGroupList appointmentGroup={mockAppointmentGroup} />)
    const reservedBadge = screen.getByText('Reserved')
    expect(reservedBadge).toBeInTheDocument()
  })

  test('handles participant list correctly', () => {
    render(<AppointmentGroupList appointmentGroup={mockAppointmentGroup} />)
    const participantList = screen.getByText('John Doe')
    expect(participantList).toBeInTheDocument()
  })

  test('renders correct number of appointments based on props', () => {
    const modifiedGroup = {
      ...mockAppointmentGroup,
      appointments: [
        ...mockAppointmentGroup.appointments,
        {
          id: '3',
          start_at: '2024-04-03T14:00:00Z',
          end_at: '2024-04-03T15:00:00Z',
          child_events: [],
        },
      ],
    }
    render(<AppointmentGroupList appointmentGroup={modifiedGroup} />)
    const appointments = screen.getAllByText(/to/)
    expect(appointments).toHaveLength(3)
  })

  test('renders participant names correctly', () => {
    const groupWithParticipants = {
      participants_per_appointment: 3,
      appointments: [
        {
          id: '1',
          start_at: '2024-04-01T10:00:00Z',
          end_at: '2024-04-01T11:00:00Z',
          child_events: [
            {user: {sortable_name: 'Smith, John'}},
            {user: {sortable_name: 'Doe, Jane'}},
          ],
          child_events_count: 2,
        },
      ],
    }
    render(<AppointmentGroupList appointmentGroup={groupWithParticipants} />)
    const participantText = screen.getByText('Doe, Jane; Smith, John; Available')
    expect(participantText).toBeInTheDocument()
  })

  test('renders group names correctly', () => {
    const groupWithNames = {
      participants_per_appointment: 3,
      appointments: [
        {
          id: '1',
          start_at: '2024-04-01T10:00:00Z',
          end_at: '2024-04-01T11:00:00Z',
          child_events: [{group: {name: 'Math 101'}}, {group: {name: 'Physics 101'}}],
          child_events_count: 2,
        },
      ],
    }
    render(<AppointmentGroupList appointmentGroup={groupWithNames} />)
    const groupText = screen.getByText('Math 101; Physics 101; Available')
    expect(groupText).toBeInTheDocument()
  })
})

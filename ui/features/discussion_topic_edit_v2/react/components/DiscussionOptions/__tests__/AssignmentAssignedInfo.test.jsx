/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {render, fireEvent, act, waitFor} from '@testing-library/react'
import React from 'react'
import {AssignmentDueDate} from '../AssignmentDueDate'
import {DateTime} from '@instructure/ui-i18n'

const setup = ({
  initialAssignedInformation = {},
  assignedListOptions = [],
  onAssignedInfoChange = () => {},
} = {}) => {
  return render(
    <AssignmentDueDate
      initialAssignedInformation={initialAssignedInformation}
      assignedListOptions={assignedListOptions}
      onAssignedInfoChange={onAssignedInfoChange}
    />
  )
}

describe('AssignmentDueDate', () => {
  // ariaLive is required to avoid unnecessary warnings
  let ariaLive

  beforeAll(() => {
    ariaLive = document.createElement('div')
    ariaLive.id = 'flash_screenreader_holder'
    ariaLive.setAttribute('role', 'alert')
    document.body.appendChild(ariaLive)
  })

  afterAll(() => {
    if (ariaLive) ariaLive.remove()
  })

  it('renders DateTimeInput fields correctly', () => {
    const {queryAllByText} = setup()

    // uses queryAllByText because DateTimeInput description gets used in some non-visual accessibility elements as well
    expect(queryAllByText('Due')[0]).toBeInTheDocument()
    expect(queryAllByText('Available from')[0]).toBeInTheDocument()
    expect(queryAllByText('Until')[0]).toBeInTheDocument()
  })

  it('sets initial values correctly', () => {
    const initialAssignedInformation = {
      dueDate: '2023-10-10',
      availableFrom: '2023-10-05',
      availableUntil: '2023-11-10',
    }
    const {queryAllByText} = setup({initialAssignedInformation})
    // uses queryAllByText because DateTimeInput formFieldMessage gets used in some non-visual accessibility elements as well
    expect(queryAllByText('Tuesday, October 10, 2023 12:00 AM')[0]).toBeInTheDocument()
    expect(queryAllByText('Thursday, October 5, 2023 12:00 AM')[0]).toBeInTheDocument()
    expect(queryAllByText('Friday, November 10, 2023 12:00 AM')[0]).toBeInTheDocument()
  })

  describe('AssignmentDueDate callbacks', () => {
    it('updates dueDate on change and triggers callback', async () => {
      const locale = 'en'
      const timeZone = DateTime.browserTimeZone()
      const onAssignedInfoChange = jest.fn()
      const initialAssignedInformation = {
        dueDate: '2023-10-17T06:00:00.000Z',
      }
      const {getByDisplayValue} = setup({initialAssignedInformation, onAssignedInfoChange})

      // Get the display value shown on the date <DateTimeInput> input
      const datestr = DateTime.toLocaleString(
        initialAssignedInformation.dueDate,
        locale,
        timeZone,
        'LL'
      )
      // Get the input based on that formatted string
      const dueDateInput = getByDisplayValue(datestr)

      // Wrap the interactions in an act to ensure correct update batching
      act(() => {
        // enter a new date
        fireEvent.change(dueDateInput, {target: {value: 'April 4, 2018'}})
        // Blur so that the <dateTimeInput> callbacks are triggered
        fireEvent.blur(dueDateInput)
      })

      // Wait for the onAssignedInfoChange to be called
      await waitFor(() => expect(onAssignedInfoChange).toHaveBeenCalled())

      // Validate callback was called with new value
      expect(onAssignedInfoChange).toHaveBeenCalledWith({
        dueDate: '2018-04-04T06:00:00.000Z',
      })
    })
  })
})

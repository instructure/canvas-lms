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
import {render, fireEvent} from '@testing-library/react'
import TimeBlockSelector from '../TimeBlockSelector'

const defaultProps = {
  timeData: [
    {
      slotEventId: '1',
      timeData: {
        date: '2016-10-26',
        startTime: '10:00',
        endTime: '15:00',
      },
    },
  ],
  onChange: jest.fn(),
}

describe('TimeBlockSelector', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders the component', () => {
    const {container} = render(<TimeBlockSelector {...defaultProps} />)
    expect(container.querySelector('.TimeBlockSelector')).toBeInTheDocument()
  })

  it('renders TimeBlockSelectRows container', () => {
    const {container} = render(<TimeBlockSelector {...defaultProps} />)
    const rowsContainer = container.querySelector('.TimeBlockSelector__Rows')
    expect(rowsContainer).toBeInTheDocument()
  })

  it('divides slots and adds new rows when using the divide section', () => {
    const ref = React.createRef()
    const {container} = render(<TimeBlockSelector {...defaultProps} ref={ref} />)

    // Set initial time block
    const initialRow = {
      slotEventId: 'test-slot',
      timeData: {
        startTime: new Date('2016-10-26T15:00:00.000Z'),
        endTime: new Date('2016-10-26T20:00:00.000Z'),
      },
    }
    ref.current.setState({
      timeBlockRows: [initialRow],
    })

    // Input division value and trigger division
    const divideInput = container.querySelector('#TimeBlockSelector__DivideSection-Input')
    fireEvent.change(divideInput, {target: {value: '60'}})
    ref.current.handleSlotDivision()

    expect(ref.current.state.timeBlockRows.length).toBeGreaterThan(1)
  })

  it('adds new time slot with specified time', () => {
    const ref = React.createRef()
    render(<TimeBlockSelector {...defaultProps} ref={ref} />)

    const initialLength = ref.current.state.timeBlockRows.length
    ref.current.addRow({
      timeData: {
        startTime: new Date('Oct 26 2016 10:00'),
        endTime: new Date('Oct 26 2016 15:00'),
      },
    })
    expect(ref.current.state.timeBlockRows).toHaveLength(initialLength + 1)
  })

  it('adds new empty time slot when no time specified', () => {
    const ref = React.createRef()
    render(<TimeBlockSelector {...defaultProps} ref={ref} />)

    const initialLength = ref.current.state.timeBlockRows.length
    ref.current.addRow()
    expect(ref.current.state.timeBlockRows).toHaveLength(initialLength + 1)
  })

  it('deletes a time slot', () => {
    const ref = React.createRef()
    render(<TimeBlockSelector {...defaultProps} ref={ref} />)

    const initialLength = ref.current.state.timeBlockRows.length
    const slotId = ref.current.state.timeBlockRows[0].slotEventId
    ref.current.deleteRow(slotId)
    expect(ref.current.state.timeBlockRows).toHaveLength(initialLength - 1)
  })

  it('updates time data for a specific slot', () => {
    const ref = React.createRef()
    render(<TimeBlockSelector {...defaultProps} ref={ref} />)

    const slotId = ref.current.state.timeBlockRows[0].slotEventId
    const newTimeData = {
      startTime: new Date('Oct 26 2016 11:00'),
      endTime: new Date('Oct 26 2016 16:00'),
    }

    ref.current.handleSetData(slotId, newTimeData)
    expect(ref.current.state.timeBlockRows[0].timeData).toEqual(newTimeData)
  })

  it('calls onChange when modifications are made', () => {
    const onChange = jest.fn()
    const ref = React.createRef()
    render(<TimeBlockSelector {...defaultProps} onChange={onChange} ref={ref} />)

    // Modify time data
    const newRow = ref.current.state.timeBlockRows[0]
    newRow.timeData = {
      startTime: new Date('Oct 26 2016 10:00'),
      endTime: new Date('Oct 26 2016 15:00'),
    }
    ref.current.setState({
      timeBlockRows: [newRow],
    })

    expect(onChange).toHaveBeenCalled()
  })
})

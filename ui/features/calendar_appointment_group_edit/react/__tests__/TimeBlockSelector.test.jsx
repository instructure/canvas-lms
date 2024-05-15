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
import TestUtils from 'react-dom/test-utils'
import {render} from '@testing-library/react'
import {shallow} from 'enzyme'
import TimeBlockSelector from '../TimeBlockSelector'
import TimeBlockSelectRow from '../TimeBlockSelectRow'
import sinon from 'sinon'

const props = {
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
  onChange() {},
}

describe('TimeBlockSelector', () => {
  test('it renders', () => {
    const wrapper = render(<TimeBlockSelector {...props} />)
    expect(wrapper).toBeTruthy()
  })

  test('it renders TimeBlockSelectRows in their own container', () => {
    // Adding new blank rows is dependent on TimeBlockSelectRows being the last
    // item in the container
    const wrapper = shallow(<TimeBlockSelector {...props} />)
    const children = wrapper.find('.TimeBlockSelector__Rows').children()
    expect(children.last().type()).toEqual(TimeBlockSelectRow)
  })

  test('handleSlotDivision divides slots and adds new rows to the selector', () => {
    const ref = React.createRef()
    const component = render(<TimeBlockSelector {...props} ref={ref} />)
    const input = component.container.querySelector('#TimeBlockSelector__DivideSection-Input')
    input.value = 60
    TestUtils.Simulate.change(input)
    const newRow = ref.current.state.timeBlockRows[0]
    newRow.timeData.startTime = new Date('2016-10-26T15:00:00.000Z')
    newRow.timeData.endTime = new Date('2016-10-26T20:00:00.000Z')
    ref.current.setState({
      timeBlockRows: [newRow, {slotEventId: 'asdf', timeData: {startTime: null, endTime: null}}],
    })
    ref.current.handleSlotDivision()
    expect(ref.current.state.timeBlockRows.length).toEqual(6)
  })

  test('handleSlotAddition adds new time slot with time', () => {
    const ref = React.createRef()
    render(<TimeBlockSelector {...props} ref={ref} />)
    const newRow = ref.current.state.timeBlockRows[0]
    newRow.timeData.startTime = new Date('Oct 26 2016 10:00')
    newRow.timeData.endTime = new Date('Oct 26 2016 15:00')
    expect(ref.current.state.timeBlockRows.length).toEqual(1)
    ref.current.addRow(newRow)
    expect(ref.current.state.timeBlockRows.length).toEqual(2)
  })

  test('handleSlotAddition adds new time slot without time', () => {
    const ref = React.createRef()
    render(<TimeBlockSelector {...props} ref={ref} />)
    expect(ref.current.state.timeBlockRows.length).toEqual(1)
    ref.current.addRow()
    expect(ref.current.state.timeBlockRows.length).toEqual(2)
  })

  test('handleSlotDeletion delete a time slot with time', () => {
    const ref = React.createRef()
    render(<TimeBlockSelector {...props} ref={ref} />)
    const newRow = ref.current.state.timeBlockRows[0]
    newRow.timeData.startTime = new Date('Oct 26 2016 10:00')
    newRow.timeData.endTime = new Date('Oct 26 2016 15:00')
    ref.current.addRow(newRow)
    expect(ref.current.state.timeBlockRows.length).toEqual(2)
    ref.current.deleteRow(ref.current.state.timeBlockRows[1].slotEventId)
    expect(ref.current.state.timeBlockRows.length).toEqual(1)
  })

  test('handleSetData setting time data', () => {
    const ref = React.createRef()
    const component = render(<TimeBlockSelector {...props} ref={ref} />)
    const newRow = ref.current.state.timeBlockRows[0]
    newRow.timeData.startTime = new Date('Oct 26 2016 10:00')
    newRow.timeData.endTime = new Date('Oct 26 2016 15:00')
    ref.current.addRow(newRow)
    newRow.timeData.startTime = new Date('Oct 26 2016 11:00')
    newRow.timeData.endTime = new Date('Oct 26 2016 16:00')
    ref.current.handleSetData(ref.current.state.timeBlockRows[1].slotEventId, newRow)
    expect(ref.current.state.timeBlockRows[0].timeData.endTime).toEqual(
      new Date('Oct 26 2016 16:00')
    )
  })

  test('calls onChange when there are modifications made', async () => {
    props.onChange = sinon.spy()
    const ref = React.createRef()
    const component = render(<TimeBlockSelector {...props} ref={ref} />)
    const input = component.container.querySelector('#TimeBlockSelector__DivideSection-Input')
    input.value = 60
    // const user = userEvent.setup({delay: null})
    // await user.focus(input)
    const newRow = ref.current.state.timeBlockRows[0]
    newRow.timeData.startTime = new Date('Oct 26 2016 10:00')
    newRow.timeData.endTime = new Date('Oct 26 2016 15:00')
    ref.current.setState({
      timeBlockRows: [newRow],
    })
    expect(props.onChange.called).toBeTruthy()
  })
})

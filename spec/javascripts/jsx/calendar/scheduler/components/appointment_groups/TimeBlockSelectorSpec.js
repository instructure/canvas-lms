/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import ReactDOM from 'react-dom'
import TestUtils from 'react-addons-test-utils'
import {mount, shallow} from 'enzyme'
import TimeBlockSelector from 'jsx/calendar/scheduler/components/appointment_groups/TimeBlockSelector'
import TimeBlockSelectRow from 'jsx/calendar/scheduler/components/appointment_groups/TimeBlockSelectRow'

let props

QUnit.module('TimeBlockSelector', {
  setup() {
    props = {
      timeData: [],
      onChange() {}
    }
  },
  teardown() {
    props = null
  }
})

test('it renders', () => {
  const wrapper = mount(<TimeBlockSelector {...props} />)
  ok(wrapper)
})

test('it renders TimeBlockSelectRows in their own container', () => {
  // Adding new blank rows is dependent on TimeBlockSelectRows being the last
  // item in the container
  const wrapper = shallow(<TimeBlockSelector {...props} />)
  const children = wrapper.find('.TimeBlockSelector__Rows').children()
  equal(children.last().type(), TimeBlockSelectRow)
})

test('handleSlotDivision divides slots and adds new rows to the selector', () => {
  const component = TestUtils.renderIntoDocument(<TimeBlockSelector {...props} />)
  const domNode = ReactDOM.findDOMNode(component)
  $('#TimeBlockSelector__DivideSection-Input', domNode).val(60)
  const newRow = component.state.timeBlockRows[0]
  newRow.timeData.startTime = new Date('Oct 26 2016 10:00')
  newRow.timeData.endTime = new Date('Oct 26 2016 15:00')
  component.setState({
    timeBlockRows: [newRow, {timeData: {startTime: null, endTime: null}}]
  })
  component.handleSlotDivision()
  equal(component.state.timeBlockRows.length, 6)
})

test('handleSlotAddition adds new time slot with time', () => {
  const component = TestUtils.renderIntoDocument(<TimeBlockSelector {...props} />)
  const newRow = component.state.timeBlockRows[0]
  newRow.timeData.startTime = new Date('Oct 26 2016 10:00')
  newRow.timeData.endTime = new Date('Oct 26 2016 15:00')
  equal(component.state.timeBlockRows.length, 1)
  component.addRow(newRow)
  equal(component.state.timeBlockRows.length, 2)
})

test('handleSlotAddition adds new time slot without time', () => {
  const component = TestUtils.renderIntoDocument(<TimeBlockSelector {...props} />)
  equal(component.state.timeBlockRows.length, 1)
  component.addRow()
  equal(component.state.timeBlockRows.length, 2)
})

test('handleSlotDeletion delete a time slot with time', () => {
  const component = TestUtils.renderIntoDocument(<TimeBlockSelector {...props} />)
  const newRow = component.state.timeBlockRows[0]
  newRow.timeData.startTime = new Date('Oct 26 2016 10:00')
  newRow.timeData.endTime = new Date('Oct 26 2016 15:00')
  component.addRow(newRow)
  equal(component.state.timeBlockRows.length, 2)
  component.deleteRow(component.state.timeBlockRows[1].slotEventId)
  equal(component.state.timeBlockRows.length, 1)
})

test('handleSetData setting time data', () => {
  const component = TestUtils.renderIntoDocument(<TimeBlockSelector {...props} />)
  const newRow = component.state.timeBlockRows[0]
  newRow.timeData.startTime = new Date('Oct 26 2016 10:00')
  newRow.timeData.endTime = new Date('Oct 26 2016 15:00')
  component.addRow(newRow)
  newRow.timeData.startTime = new Date('Oct 26 2016 11:00')
  newRow.timeData.endTime = new Date('Oct 26 2016 16:00')
  component.handleSetData(component.state.timeBlockRows[1].slotEventId, newRow)
  deepEqual(component.state.timeBlockRows[0].timeData.endTime, new Date('Oct 26 2016 16:00'))
})

test('calls onChange when there are modifications made', () => {
  props.onChange = sinon.spy()
  const component = TestUtils.renderIntoDocument(<TimeBlockSelector {...props} />)
  const domNode = ReactDOM.findDOMNode(component)
  $('#TimeBlockSelector__DivideSection-Input', domNode).val(60)
  const newRow = component.state.timeBlockRows[0]
  newRow.timeData.startTime = new Date('Oct 26 2016 10:00')
  newRow.timeData.endTime = new Date('Oct 26 2016 15:00')
  component.setState({
    timeBlockRows: [newRow]
  })
  ok(props.onChange.called)
})

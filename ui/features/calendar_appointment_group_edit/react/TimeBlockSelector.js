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
import PropTypes from 'prop-types'
import I18n from 'i18n!appointment_groups'
import TimeBlockListManager from '@canvas/calendar/TimeBlockListManager'
import '@canvas/datetime'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {NumberInput} from '@instructure/ui-number-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Button} from '@instructure/ui-buttons'
import TimeBlockSelectRow from './TimeBlockSelectRow'
import NumberHelper from '@canvas/i18n/numberHelper'

const uniqueId = (() => {
  let count = 0
  return () => `NEW-${++count}`
})()

export default class TimeBlockSelector extends React.Component {
  static propTypes = {
    className: PropTypes.string,
    timeData: PropTypes.arrayOf(PropTypes.object),
    onChange: PropTypes.func.isRequired
  }

  constructor(props) {
    super(props)
    this.state = {
      timeBlockRows: [
        {
          slotEventId: uniqueId(),
          timeData: {}
        }
      ],
      slotValue: '30',
      slotMessage: null
    }
  }

  componentDidUpdate(prevProps, prevState) {
    if (prevState.timeBlockRows !== this.state.timeBlockRows) {
      this.props.onChange(this.state.timeBlockRows)
    }
  }

  getNewSlotData() {
    return this.state.timeBlockRows.reduce((acc, tbr) => {
      if (tbr.timeData.startTime && tbr.timeData.endTime) {
        acc.push([tbr.timeData.startTime, tbr.timeData.endTime, false])
      }
      return acc
    }, [])
  }

  deleteRow = slotEventId => {
    const newRows = this.state.timeBlockRows.filter(e => e.slotEventId !== slotEventId)
    this.setState({
      timeBlockRows: newRows
    })
  }

  addRow = (timeData = {}) => {
    const newRows = [
      {
        slotEventId: uniqueId(),
        timeData
      }
    ]
    this.setState({
      timeBlockRows: this.state.timeBlockRows.concat(newRows)
    })
  }

  addRowsFromBlocks = timeBlocks => {
    const newRows = timeBlocks.map(tb => ({
      slotEventId: uniqueId(),
      timeData: tb
    }))
    // Make sure a new blank row is there as well.
    newRows.push({
      slotEventId: uniqueId(),
      timeData: {}
    })
    this.setState({
      timeBlockRows: newRows
    })
  }

  formatDate = date => {
    if (date.toDate) {
      return date.toDate()
    }
    return date
  }

  handleSlotDivision = () => {
    const node = ReactDOM.findDOMNode(this)
    const minuteValue = $('#TimeBlockSelector__DivideSection-Input', node).val()
    if (!NumberHelper.validate(minuteValue)) {
      return
    }
    const timeManager = new TimeBlockListManager(this.getNewSlotData())
    timeManager.split(minuteValue)
    const newBlocks = timeManager.blocks.map(block => ({
      date: this.formatDate(block.start),
      startTime: this.formatDate(block.start),
      endTime: this.formatDate(block.end)
    }))
    this.addRowsFromBlocks(newBlocks)
  }

  handleSetData = (timeslotId, data) => {
    const newRows = this.state.timeBlockRows.slice()
    const rowToUpdate = newRows.find(r => r.slotEventId === timeslotId)
    rowToUpdate.timeData = data
    this.setState({
      timeBlockRows: newRows
    })
  }

  isSlotValueValid(value) {
    const val = NumberHelper.parse(value)
    return value.trim().length === 0 || (!Number.isNaN(val) && val > 0)
  }

  handleSlotValueChange = (_event, slotValue) => {
    const slotMessage = this.isSlotValueValid(slotValue)
      ? null
      : [{type: 'error', text: I18n.t('Must be a number > 0')}]
    this.setState({slotValue, slotMessage})
  }

  handleSlotValueIncrement = () => {
    this.setState((state, _props) => {
      const val = NumberHelper.parse(state.slotValue)
      if (Number.isNaN(val)) {
        // current value can't be incremented, do nothing
        return null
      }
      return {
        slotValue: val + 1,
        slotMessage: null
      }
    })
  }

  handleSlotValueDecrement = () => {
    this.setState((state, _props) => {
      const val = NumberHelper.parse(state.slotValue)
      if (Number.isNaN(val)) {
        // current value can't be decremented, do nothing
        return null
      }
      return {
        slotValue: val > 1 ? val - 1 : val,
        slotMessage: null
      }
    })
  }

  render() {
    return (
      <div className="TimeBlockSelector">
        <div className="TimeBlockSelector__Rows">
          {this.props.timeData.map(timeBlock => (
            <TimeBlockSelectRow {...timeBlock} key={timeBlock.slotEventId} readOnly />
          ))}
          {this.state.timeBlockRows.map(timeBlock => (
            <TimeBlockSelectRow
              key={timeBlock.slotEventId}
              handleDelete={this.deleteRow}
              onBlur={this.addRow}
              setData={this.handleSetData}
              {...timeBlock}
            />
          ))}
        </div>
        <FormFieldGroup
          layout="columns"
          vAlign="bottom"
          description={
            <ScreenReaderContent>
              {I18n.t('Divide into equal time slots (in minutes')}
            </ScreenReaderContent>
          }
          messages={this.state.slotMessage}
        >
          <NumberInput
            renderLabel={I18n.t('Divide into equal slots (value is in minutes)')}
            value={this.state.slotValue}
            onChange={this.handleSlotValueChange}
            onIncrement={this.handleSlotValueIncrement}
            onDecrement={this.handleSlotValueDecrement}
            id="TimeBlockSelector__DivideSection-Input"
          />
          <Button onClick={this.handleSlotDivision}>{I18n.t('Create Slots')}</Button>
        </FormFieldGroup>
      </div>
    )
  }
}

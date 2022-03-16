/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import moment from 'moment-timezone'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {TextInput} from '@instructure/ui-text-input'

import CoursePaceDateInput from './course_pace_date_input'
import {BlackoutDate} from '../types'
import * as DateHelpers from '../../utils/date_stuff/date_helpers'

interface PassedProps {
  readonly addBlackoutDate: (blackoutDate: BlackoutDate) => any
}

interface LocalState {
  readonly eventTitle: string
  readonly startDate: string
  readonly endDate: string
}

class NewBlackoutDatesForm extends React.Component<PassedProps, LocalState> {
  constructor(props: PassedProps) {
    super(props)
    this.state = {eventTitle: '', startDate: '', endDate: ''}
  }

  /* Callbacks */

  addBlackoutDate = () => {
    const blackoutDate: BlackoutDate = {
      event_title: this.state.eventTitle,
      start_date: moment(this.state.startDate),
      end_date: moment(this.state.endDate)
    }

    this.props.addBlackoutDate(blackoutDate)
    this.setState({eventTitle: '', startDate: '', endDate: ''})
  }

  onChangeEventTitle = (e: React.FormEvent<HTMLInputElement>) => {
    if (e.currentTarget.value.length <= 100) {
      this.setState({eventTitle: e.currentTarget.value})
    }
  }

  onChangeStartDate = (date: string) => {
    const startDate = DateHelpers.formatDate(date)
    this.setState(({endDate}) => ({startDate, endDate: endDate || startDate}))
  }

  onChangeEndDate = (date: string) => {
    this.setState({endDate: DateHelpers.formatDate(date)})
  }

  disabledAdd = () => {
    return this.state.eventTitle.length < 1 || !this.state.startDate || !this.state.endDate
  }

  /* Renderers */

  render() {
    return (
      <div>
        <Flex alignItems="end" justifyItems="space-between" wrap="wrap" margin="0 0 large">
          <TextInput
            renderLabel="Event Title"
            placeholder="e.g., Winter Break"
            width="180px"
            value={this.state.eventTitle}
            onChange={this.onChangeEventTitle}
          />
          <CoursePaceDateInput
            dateValue={this.state.startDate}
            label="Start Date"
            onDateChange={this.onChangeStartDate}
            endDate={this.state.endDate}
            width="140px"
          />
          <CoursePaceDateInput
            dateValue={this.state.endDate}
            label="End Date"
            onDateChange={this.onChangeEndDate}
            startDate={this.state.startDate}
            width="140px"
          />
          <Button
            color="primary"
            interaction={this.disabledAdd() ? 'disabled' : 'enabled'}
            onClick={this.addBlackoutDate}
          >
            Add
          </Button>
        </Flex>
      </div>
    )
  }
}

export default NewBlackoutDatesForm

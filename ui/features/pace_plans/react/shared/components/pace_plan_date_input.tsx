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

/*
 * A wrapper around the instructure-ui DateInput component
 *
 * This wrapper does the following:
 *
 * - Renders the DateInput with the passed in props
 * - Handles date changes and ensures the user doesn't manually enter a disabled date
 * - Includes a hack to make sure the DateInput's TextInput updates (see componentWillReceiveProps)
 */

import React from 'react'
import moment from 'moment-timezone'
import tz from '@canvas/timezone'

import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'

import CanvasDateInput from '@canvas/datetime/react/components/DateInput'
import * as DateHelpers from '../../utils/date_stuff/date_helpers'
import {InputInteraction} from '../types'

export enum DateErrorMessages {
  INVALID_FORMAT = 'Invalid date entered. Date has been reset.',
  DISABLED_WEEKEND = 'Weekends are disabled. Date has been shifted to the nearest weekday.',
  DISABLED_OTHER = 'Disabled day entered. Date has been reset.'
}

interface PassedProps {
  readonly dateValue?: string
  readonly label: string | JSX.Element
  readonly onDateChange: (rawDate: string) => any
  // array representing the disabled days of the week (e.g., [0,6] for Saturday and Sunday)
  readonly disabledDaysOfWeek?: number[]
  // callback that takes a date and returns if it should be disabled or not
  readonly disabledDays?: (date: moment.Moment) => boolean
  readonly width?: string
  readonly layout?: 'inline' | 'stacked'
  readonly inline?: boolean
  readonly interaction?: InputInteraction
  readonly id: string
  readonly placeholder?: string
  readonly locale?: string
}

interface LocalState {
  readonly error?: string
}

class PacePlanDateInput extends React.Component<PassedProps, LocalState> {
  state: LocalState = {
    error: undefined
  }

  public static defaultProps: Partial<PassedProps> = {
    disabledDaysOfWeek: [],
    disabledDays: [] as any,
    width: '135',
    layout: 'stacked',
    inline: false,
    interaction: 'enabled',
    placeholder: 'Select a date',
    locale: window.ENV.LOCALE
  }

  /* Callbacks */

  onDateChange = newDate => {
    let error: string | undefined
    let parsedDate = moment(newDate).startOf('day')

    const landsOnDisabledWeekend =
      this.props.disabledDaysOfWeek && this.props.disabledDaysOfWeek.includes(parsedDate.weekday())
    const landsOnDisabledDay = this.props.disabledDays && this.props.disabledDays(parsedDate)
    const dateIsDisabled = landsOnDisabledWeekend || landsOnDisabledDay

    if (!parsedDate.isValid()) {
      parsedDate = moment(this.props.dateValue)
      error = DateErrorMessages.INVALID_FORMAT
    } else if (dateIsDisabled) {
      if (landsOnDisabledDay) {
        // If the date was disabled because of the disabledDays function, just reset it and don't try to shift
        parsedDate = moment(this.props.dateValue)
        error = DateErrorMessages.DISABLED_OTHER
      } else if (landsOnDisabledWeekend) {
        parsedDate = moment(DateHelpers.adjustDateOnSkipWeekends(newDate))
        error = DateErrorMessages.DISABLED_WEEKEND
      } else {
        parsedDate = moment(this.props.dateValue)
        error = DateErrorMessages.DISABLED_OTHER
      }
    }

    // Regardless of the displayed format, we should store it as YYYY-MM-DD
    this.props.onDateChange(parsedDate.format('YYYY-MM-DD'))

    this.setState({error})
  }

  formatDate = date => tz.format(date, 'date.formats.long')

  /* Renderers */

  render() {
    const {dateValue} = this.props
    if (this.props.interaction === 'readonly') {
      return (
        <div style={{display: 'inline-block', lineHeight: '1.125rem'}}>
          <View as="div" margin="0 0 small">
            <Text weight="bold">{this.props.label}</Text>
          </View>
          <Flex as="div" height="2.25rem" alignItems="center">
            {this.formatDate(dateValue)}
          </Flex>
        </div>
      )
    }
    return (
      <CanvasDateInput
        renderLabel={this.props.label}
        formatDate={this.formatDate}
        onSelectedDateChange={this.onDateChange}
        selectedDate={dateValue && moment(dateValue).isValid() ? dateValue : ''}
        width={this.props.width}
        messages={this.state.error ? [{type: 'error', text: this.state.error}] : []}
        interaction={this.props.interaction}
      />
    )
  }
}

export default PacePlanDateInput

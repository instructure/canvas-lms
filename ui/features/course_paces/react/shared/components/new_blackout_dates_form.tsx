// @ts-nocheck
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
import {Responsive} from '@instructure/ui-responsive'
import {Tooltip} from '@instructure/ui-tooltip'
import {TextInput} from '@instructure/ui-text-input'
import CanvasDateInput, {
  CanvasDateInputMessageType,
} from '@canvas/datetime/react/components/DateInput'
import {coursePaceTimezone} from '../api/backend_serializer'

import {BlackoutDate} from '../types'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('course_paces_app')

const dateTimeFormatter = new Intl.DateTimeFormat(ENV.LOCALE, {
  month: 'numeric',
  day: 'numeric',
  year: 'numeric',
  timeZone: coursePaceTimezone,
})

function formatDate(date): string {
  return dateTimeFormatter.format(date)
}

interface PassedProps {
  readonly addBlackoutDate: (blackoutDate: BlackoutDate) => any
}

interface LocalState {
  readonly eventTitle: string
  readonly startDate: string
  readonly endDate: string
  readonly titleMessages: CanvasDateInputMessageType[]
  readonly startMessages: CanvasDateInputMessageType[]
  readonly endMessages: CanvasDateInputMessageType[]
  readonly key: number
}

class NewBlackoutDatesForm extends React.Component<PassedProps, LocalState> {
  private static missingInput = I18n.t('You must provide required fields before adding')

  private titleInputRef: HTMLInputElement | undefined

  constructor(props: PassedProps) {
    super(props)
    this.state = {
      eventTitle: '',
      startDate: '',
      endDate: '',
      titleMessages: [],
      startMessages: [],
      endMessages: [],
      key: 1,
    }
    this.titleInputRef = undefined
  }

  addBlackoutDate = () => {
    const blackoutDate: BlackoutDate = {
      event_title: this.state.eventTitle.trim(),
      start_date: moment(this.state.startDate || this.state.endDate),
      end_date: moment(this.state.endDate || this.state.startDate),
    }

    this.props.addBlackoutDate(blackoutDate)
    this.setState((state, _props) => ({
      eventTitle: '',
      startDate: '',
      endDate: '',
      startMessages: [],
      endMessages: [],
      key: state.key + 1,
    }))
  }

  onChangeEventTitle = (e: React.FormEvent<HTMLInputElement>) => {
    const newTitle = e.currentTarget.value
    if (newTitle.length <= 100) {
      this.setState({
        eventTitle: newTitle,
        titleMessages: [],
      })
    }
  }

  validateTitle = () => {
    if (this.titleInputRef?.value.trim().length === 0) {
      this.setState({
        titleMessages: [{type: 'error' as const, text: I18n.t('Title required')}],
      })
    }
  }

  validateDates = (): void => {
    this.setState((state, _props) => {
      let startMessages: CanvasDateInputMessageType[] = []
      let endMessages: CanvasDateInputMessageType[] = []

      if (!(state.startDate || state.endDate)) {
        startMessages = [
          {
            type: 'error' as const,
            text: I18n.t('Date required'),
          },
        ]
      } else {
        const startDate = new Date(state.startDate)
        const endDate = new Date(state.endDate)
        if (startDate.valueOf() > endDate.valueOf()) {
          endMessages = [
            {
              type: 'error' as const,
              text: I18n.t('End date cannot be before start date'),
            },
          ]
        }
      }
      return {startMessages, endMessages}
    })
  }

  validateEverything = (): void => {
    this.validateDates()
    this.validateTitle()
  }

  onChangeStartDate = (date: Date | null) => {
    this.setState({startDate: date ? date.toISOString() : ''}, () => this.validateDates())
  }

  onBlurDate = () => {
    this.validateDates()
  }

  onChangeEndDate = (date: Date | null) => {
    this.setState(
      {
        endDate: date ? date.toISOString() : '',
      },
      () => this.validateDates()
    )
  }

  disabledAdd = () => {
    return (
      this.state.eventTitle.trim().length < 1 ||
      !(this.state.startDate || this.state.endDate) ||
      !!(this.state.startDate && this.state.endDate && this.state.endDate < this.state.startDate)
    )
  }

  /* Renderers */

  render() {
    return (
      <Responsive
        match="media"
        query={{
          smallest: {maxWidth: '432px'},
          smaller: {maxWidth: '576px'},
          small: {maxWidth: '635px'},
          large: {minWidth: '635px'},
        }}
        render={(_props, matches) => {
          let addBtnMarginTop = '0'
          if (
            !matches.includes('smallest') &&
            (matches.includes('smaller') || matches.includes('large'))
          ) {
            addBtnMarginTop = 'calc(1.75rem + 2px)'
          }
          return (
            <div data-testid="new_blackout_dates_form">
              <Flex alignItems="start" justifyItems="start" wrap="wrap">
                <Flex.Item margin="0 small small 0">
                  <TextInput
                    inputRef={el => (this.titleInputRef = el)}
                    renderLabel="Event Title"
                    placeholder="e.g., Winter Break"
                    width="180px"
                    value={this.state.eventTitle}
                    onChange={this.onChangeEventTitle}
                    onBlur={this.validateTitle}
                    messages={this.state.titleMessages}
                  />
                </Flex.Item>
                <Flex.Item>
                  <Flex alignItems="start" justifyItems="space-between" wrap="wrap">
                    <Flex.Item data-testid="blackout-start-date" margin="0 small small 0">
                      <CanvasDateInput
                        key={`start-${this.state.key}`}
                        renderLabel={I18n.t('Start Date')}
                        timezone={coursePaceTimezone}
                        formatDate={formatDate}
                        onSelectedDateChange={this.onChangeStartDate}
                        onBlur={this.onBlurDate}
                        selectedDate={this.state.startDate}
                        width="140px"
                        messages={this.state.startMessages}
                        withRunningValue={true}
                      />
                    </Flex.Item>
                    <Flex.Item data-testid="blackout-end-date" margin="0 small small 0">
                      <CanvasDateInput
                        key={`end-${this.state.key}`}
                        renderLabel={I18n.t('End Date')}
                        timezone={coursePaceTimezone}
                        formatDate={formatDate}
                        onSelectedDateChange={this.onChangeEndDate}
                        onBlur={this.onBlurDate}
                        width="140px"
                        messages={this.state.endMessages}
                        withRunningValue={true}
                      />
                    </Flex.Item>
                  </Flex>
                </Flex.Item>
                <Flex.Item margin="0 0 small">
                  <div style={{marginTop: addBtnMarginTop}}>
                    <Tooltip
                      renderTip={this.disabledAdd() && NewBlackoutDatesForm.missingInput}
                      on={this.disabledAdd() ? ['hover', 'focus', 'click'] : []}
                    >
                      <Button
                        color="primary"
                        onClick={() => {
                          !this.disabledAdd() && this.addBlackoutDate()
                        }}
                        onFocus={this.validateEverything}
                      >
                        Add
                      </Button>
                    </Tooltip>
                  </div>
                </Flex.Item>
              </Flex>
            </div>
          )
        }}
      />
    )
  }
}

export default NewBlackoutDatesForm

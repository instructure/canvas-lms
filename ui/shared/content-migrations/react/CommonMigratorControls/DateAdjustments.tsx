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

import React, {useEffect, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import CanvasDateInput2 from '@canvas/datetime/react/components/DateInput2'
import {datetimeString} from '@canvas/datetime/date-functions'
import {canvas} from '@instructure/ui-themes'
import {PresentationContent, ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {View} from '@instructure/ui-view'
import {IconAddLine} from '@instructure/ui-icons'
import {Button} from '@instructure/ui-buttons'
import {Responsive} from '@instructure/ui-responsive'
import {cloneDeep} from 'lodash'
import DaySubstitution from './DaySubstitution'
import type {DateAdjustmentConfig, DaySub} from './types'
import {timeZonedFormMessages} from './timeZonedFormMessages'

const I18n = createI18nScope('content_migrations_redesign')
let subs_id = 1

const formatDate = (date: Date) => {
  return datetimeString(date, {timezone: ENV.TIMEZONE})
}

export const DateAdjustments = ({
  dateAdjustmentConfig,
  setDateAdjustments,
  disabled,
}: {
  dateAdjustmentConfig: DateAdjustmentConfig
  setDateAdjustments: (arg0: DateAdjustmentConfig) => void
  disabled?: boolean
}) => {
  const old_start_date = dateAdjustmentConfig.date_shift_options.old_start_date
  const new_start_date = dateAdjustmentConfig.date_shift_options.new_start_date
  const old_end_date = dateAdjustmentConfig.date_shift_options.old_end_date
  const new_end_date = dateAdjustmentConfig.date_shift_options.new_end_date

  const [dateOperation, setDateOperation] = useState<'shift_dates' | 'remove_dates'>('shift_dates')
  const [start_from_date, setOldStartDate] = useState<string>(old_start_date || '')
  const [start_to_date, setStartToDate] = useState<string>(new_start_date || '')
  const [end_from_date, setEndFromDate] = useState<string>(old_end_date || '')
  const [end_to_date, setEndToDate] = useState<string>(new_end_date || '')

  useEffect(() => {
    if (dateAdjustmentConfig) {
      setOldStartDate(old_start_date || '')
      setStartToDate(new_start_date || '')
      setEndFromDate(old_end_date || '')
      setEndToDate(new_end_date || '')
    }
  }, [dateAdjustmentConfig, new_end_date, new_start_date, old_end_date, old_start_date])

  const handleSetDate = (date: Date | null, setter: any, key: string) => {
    const tmp = JSON.parse(JSON.stringify(dateAdjustmentConfig))
    tmp.date_shift_options[key] = date ? date.toISOString() : ''
    setDateAdjustments(tmp)
    setter(date ? date.toISOString() : '')
  }

  const setSubstitution = (id: number, data: any, to_or_from: 'to' | 'from') => {
    const tmp = cloneDeep(dateAdjustmentConfig)
    const subIndex = tmp.date_shift_options.day_substitutions.findIndex(
      (sub: DaySub) => sub.id === id,
    )
    tmp.date_shift_options.day_substitutions[subIndex][to_or_from] = data.value
    setDateAdjustments(tmp)
  }

  const removeSubstitution = (substitution: DaySub) => {
    const tmp = cloneDeep(dateAdjustmentConfig)
    tmp.date_shift_options.day_substitutions =
      dateAdjustmentConfig.date_shift_options.day_substitutions.filter(
        (sub: DaySub) => sub.id !== substitution.id,
      )
    setDateAdjustments(tmp)
  }

  const changeDateOperation = (operation: 'shift_dates' | 'remove_dates') => {
    setDateOperation(operation)
    const tmp = JSON.parse(JSON.stringify(dateAdjustmentConfig))
    tmp.adjust_dates.operation = operation
    setDateAdjustments(tmp)
  }

  if (!dateAdjustmentConfig) {
    return null
  }

  const courseTimeZone = ENV.CONTEXT_TIMEZONE || ''
  const userTimeZone = ENV.TIMEZONE

  return (
    <Responsive
      match="media"
      query={{
        small: {maxWidth: canvas.breakpoints.desktop},
      }}
    >
      {(_props, matches) => {
        const isMobileView = matches?.includes('small') || false
        return (
          <View as="div" margin="medium none none none">
            <RadioInputGroup
              onChange={(_e: React.ChangeEvent<HTMLInputElement>, value: string) => {
                const treated_value = value as 'shift_dates' | 'remove_dates'
                changeDateOperation(treated_value)
              }}
              disabled={disabled}
              name="date_operation"
              defaultValue="shift_dates"
              layout="stacked"
              description={I18n.t('Date adjustments')}
            >
              <RadioInput
                name="date_operation"
                value="shift_dates"
                label={I18n.t('Shift dates')}
                checked={dateOperation === 'shift_dates'}
              />
              <RadioInput
                name="date_operation"
                value="remove_dates"
                data-testid="remove-dates"
                label={I18n.t('Remove dates')}
                checked={dateOperation === 'remove_dates'}
              />
            </RadioInputGroup>
            {dateOperation === 'shift_dates' ? (
              <>
                <View as="div" margin="medium none none none">
                  <Text weight="bold">{I18n.t('Beginning date:')}</Text>
                  <Flex
                    as="div"
                    padding="xx-small 0 0 0"
                    direction={isMobileView ? 'column' : 'row'}
                    alignItems="stretch"
                  >
                    <CanvasDateInput2
                      selectedDate={start_from_date}
                      onSelectedDateChange={d => {
                        handleSetDate(d, setOldStartDate, 'old_start_date')
                      }}
                      formatDate={formatDate}
                      placeholder={I18n.t('Select a date (optional)')}
                      renderLabel={
                        <ScreenReaderContent>
                          {I18n.t('Select original beginning date')}
                        </ScreenReaderContent>
                      }
                      interaction={disabled ? 'disabled' : 'enabled'}
                      width={isMobileView ? '100%' : '18.5rem'}
                      messages={timeZonedFormMessages(
                        courseTimeZone,
                        userTimeZone,
                        start_from_date,
                      )}
                      dataTestid="old_start_date"
                    />
                    <View
                      as="div"
                      width={isMobileView ? '100%' : '7.5rem'}
                      textAlign={isMobileView ? 'start' : 'center'}
                      margin={isMobileView ? 'small 0' : 'x-small x-small 0'}
                      tabIndex={-1}
                    >
                      <span style={{whiteSpace: 'nowrap'}}>{I18n.t('change to')}</span>
                    </View>
                    <CanvasDateInput2
                      selectedDate={start_to_date}
                      onSelectedDateChange={d => {
                        handleSetDate(d, setStartToDate, 'new_start_date')
                      }}
                      formatDate={formatDate}
                      placeholder={I18n.t('Select a date (optional)')}
                      renderLabel={
                        <ScreenReaderContent>
                          {I18n.t('Select new beginning date')}
                        </ScreenReaderContent>
                      }
                      interaction={disabled ? 'disabled' : 'enabled'}
                      width={isMobileView ? '100%' : '18.5rem'}
                      messages={timeZonedFormMessages(courseTimeZone, userTimeZone, start_to_date)}
                      dataTestid="new_start_date"
                    />
                  </Flex>
                </View>
                <View as="div" margin="medium none none none">
                  <Text weight="bold">{I18n.t('Ending date:')}</Text>
                  <Flex
                    as="div"
                    padding="xx-small 0 0 0"
                    direction={isMobileView ? 'column' : 'row'}
                    alignItems="stretch"
                  >
                    <CanvasDateInput2
                      selectedDate={end_from_date}
                      onSelectedDateChange={d => {
                        handleSetDate(d, setEndFromDate, 'old_end_date')
                      }}
                      formatDate={formatDate}
                      placeholder={I18n.t('Select a date (optional)')}
                      renderLabel={
                        <ScreenReaderContent>
                          {I18n.t('Select original end date')}
                        </ScreenReaderContent>
                      }
                      interaction={disabled ? 'disabled' : 'enabled'}
                      width={isMobileView ? '100%' : '18.5rem'}
                      messages={timeZonedFormMessages(courseTimeZone, userTimeZone, end_from_date)}
                      dataTestid="old_end_date"
                    />
                    <View
                      as="div"
                      width={isMobileView ? '100%' : '7.5rem'}
                      textAlign={isMobileView ? 'start' : 'center'}
                      margin={isMobileView ? 'small 0' : 'x-small x-small 0'}
                      tabIndex={-1}
                    >
                      <span style={{whiteSpace: 'nowrap'}}>{I18n.t('change to')}</span>
                    </View>
                    <CanvasDateInput2
                      selectedDate={end_to_date}
                      onSelectedDateChange={d => {
                        handleSetDate(d, setEndToDate, 'new_end_date')
                      }}
                      formatDate={formatDate}
                      placeholder={I18n.t('Select a date (optional)')}
                      renderLabel={
                        <ScreenReaderContent>{I18n.t('Select new end date')}</ScreenReaderContent>
                      }
                      interaction={disabled ? 'disabled' : 'enabled'}
                      width={isMobileView ? '100%' : '18.5rem'}
                      messages={timeZonedFormMessages(courseTimeZone, userTimeZone, end_to_date)}
                      dataTestid="new_end_date"
                    />
                  </Flex>
                </View>
                {dateAdjustmentConfig.date_shift_options.day_substitutions.map(substitution => (
                  <DaySubstitution
                    key={substitution.id}
                    substitution={substitution}
                    isMobileView={isMobileView}
                    disabled={disabled}
                    onChangeSubstitution={setSubstitution}
                    onRemoveSubstitution={removeSubstitution}
                  />
                ))}
                <Flex as="div" direction={isMobileView ? 'column' : 'row'}>
                  <Button
                    data-testid="substitution-button"
                    margin="medium none none none"
                    onClick={() => {
                      const tmp = JSON.parse(JSON.stringify(dateAdjustmentConfig))
                      tmp.date_shift_options.day_substitutions.push({from: 0, to: 0, id: subs_id++})
                      setDateAdjustments(tmp)
                    }}
                    color="secondary"
                    width={isMobileView ? '100%' : '8.5rem'}
                    disabled={disabled}
                    textAlign="center"
                    interaction={disabled ? 'disabled' : 'enabled'}
                  >
                    <PresentationContent>
                      <IconAddLine /> {I18n.t('Substitution')}
                    </PresentationContent>
                    <ScreenReaderContent>{I18n.t('Add substitution')}</ScreenReaderContent>
                  </Button>
                </Flex>
              </>
            ) : null}
            {isMobileView && (
              <hr role="presentation" aria-hidden="true" style={{margin: '1.5rem 0 0 0'}} />
            )}
          </View>
        )
      }}
    </Responsive>
  )
}

export default DateAdjustments

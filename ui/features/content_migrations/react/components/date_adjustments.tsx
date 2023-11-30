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

import React, {useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import CanvasDateInput from '@canvas/datetime/react/components/DateInput'
import {datetimeString} from '@canvas/datetime/date-functions'
import {PresentationContent, ScreenReaderContent} from '@instructure/ui-a11y-content'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {View} from '@instructure/ui-view'
import {IconAddLine, IconEndLine} from '@instructure/ui-icons'
import {IconButton, Button} from '@instructure/ui-buttons'
import {Responsive} from '@instructure/ui-responsive'
import type {DateAdjustmentConfig, submitMigrationFormData, DaySub} from './types'

const I18n = useI18nScope('content_migrations_redesign')
let subs_id = 1

const formatDate = (date: Date) => {
  return datetimeString(date, {timezone: ENV.CONTEXT_TIMEZONE})
}

export const remapSubstitutions = (
  data: submitMigrationFormData,
  dateShiftCfg: DateAdjustmentConfig
) => {
  const treated_subs: {[key: number]: number} = {}
  data.date_shift_options = dateShiftCfg.date_shift_options
  data.date_shift_options.day_substitutions.forEach((ds: DaySub) => {
    treated_subs[ds.from] = ds.to
  })
  data.date_shift_options.substitutions = treated_subs
}

export const DateAdjustments = ({
  dateAdjustments,
  setDateAdjustments,
}: {
  dateAdjustments: DateAdjustmentConfig | false
  setDateAdjustments: (arg0: DateAdjustmentConfig) => void
}) => {
  const [dateOperation, setDateOperation] = useState<'shift_dates' | 'remove_dates'>('shift_dates')
  const [start_from_date, setStartFromDate] = useState('')
  const [start_to_date, setStartToDate] = useState('')
  const [end_from_date, setEndFromDate] = useState('')
  const [end_to_date, setEndToDate] = useState('')

  const handleSetDate = (date: Date | null, setter: any, key: string) => {
    const tmp = JSON.parse(JSON.stringify(dateAdjustments))
    tmp.date_shift_options[key] = date ? date.toISOString() : ''
    setDateAdjustments(tmp)
    setter(date ? date.toISOString() : '')
  }

  const setSubstitution = (id: number, data: any, to_or_from: 'to' | 'from') => {
    const tmp = JSON.parse(JSON.stringify(dateAdjustments))
    tmp.date_shift_options.day_substitutions.map((ds: DaySub) => {
      if (ds.id !== id) return ds
      ds[to_or_from] = data.value
      return ds
    })
    setDateAdjustments(tmp)
  }

  const changeDateOperation = (operation: 'shift_dates' | 'remove_dates') => {
    setDateOperation(operation)
    const tmp = JSON.parse(JSON.stringify(dateAdjustments))
    tmp.adjust_dates.operation = operation
    setDateAdjustments(tmp)
  }

  const weekDays = [
    {key: 'Sun', name: I18n.t('Sunday')},
    {key: 'Mon', name: I18n.t('Monday')},
    {key: 'Tue', name: I18n.t('Tuesday')},
    {key: 'Wed', name: I18n.t('Wednesday')},
    {key: 'Thu', name: I18n.t('Thursday')},
    {key: 'Fri', name: I18n.t('Friday')},
    {key: 'Sat', name: I18n.t('Saturday')},
  ]

  if (!dateAdjustments) {
    return null
  }

  return (
    <Responsive
      match="media"
      query={{
        small: {maxWidth: 600},
        medium: {minWidth: 600},
        large: {minWidth: 800},
      }}
    >
      {(_props, matches) => {
        return (
          <View as="div" margin="medium none none none">
            <RadioInputGroup
              onChange={(_e: React.ChangeEvent<HTMLInputElement>, value: string) => {
                const treated_value = value as 'shift_dates' | 'remove_dates'
                changeDateOperation(treated_value)
              }}
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
                    direction={matches?.includes('small') ? 'column' : 'row'}
                  >
                    <CanvasDateInput
                      selectedDate={start_from_date}
                      onSelectedDateChange={d => {
                        handleSetDate(d, setStartFromDate, 'old_start_date')
                      }}
                      formatDate={formatDate}
                      placeholder={I18n.t('Select a date (optional)')}
                      renderLabel={
                        <ScreenReaderContent>
                          {I18n.t('Select original beginning date')}
                        </ScreenReaderContent>
                      }
                      interaction="enabled"
                      width={matches?.includes('small') ? '100%' : '18.75rem'}
                    />
                    <View
                      as="div"
                      width={matches?.includes('small') ? '100%' : '7.5rem'}
                      textAlign={matches?.includes('small') ? 'start' : 'center'}
                      margin={matches?.includes('small') ? 'small 0' : '0'}
                      tabIndex={-1}
                    >
                      {I18n.t('change to')}
                    </View>
                    <CanvasDateInput
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
                      interaction="enabled"
                      width={matches?.includes('small') ? '100%' : '18.75rem'}
                    />
                  </Flex>
                </View>
                <View as="div" margin="medium none none none">
                  <Text weight="bold">{I18n.t('Ending date:')}</Text>
                  <Flex
                    as="div"
                    padding="xx-small 0 0 0"
                    direction={matches?.includes('small') ? 'column' : 'row'}
                  >
                    <CanvasDateInput
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
                      interaction="enabled"
                      width={matches?.includes('small') ? '100%' : '18.75rem'}
                    />
                    <View
                      as="div"
                      width={matches?.includes('small') ? '100%' : '7.5rem'}
                      textAlign={matches?.includes('small') ? 'start' : 'center'}
                      margin={matches?.includes('small') ? 'small 0' : '0'}
                      tabIndex={-1}
                    >
                      {I18n.t('change to')}
                    </View>
                    <CanvasDateInput
                      selectedDate={end_to_date}
                      onSelectedDateChange={d => {
                        handleSetDate(d, setEndToDate, 'new_end_date')
                      }}
                      formatDate={formatDate}
                      placeholder={I18n.t('Select a date (optional)')}
                      renderLabel={
                        <ScreenReaderContent>{I18n.t('Select new end date')}</ScreenReaderContent>
                      }
                      interaction="enabled"
                      width={matches?.includes('small') ? '100%' : '18.75rem'}
                    />
                  </Flex>
                </View>
                {dateAdjustments.date_shift_options.day_substitutions.map(substitution => (
                  <View as="div" margin="medium none none none" key={substitution.id}>
                    <Text weight="bold">{I18n.t('Move to:')}</Text>
                    <Flex as="div" direction={matches?.includes('small') ? 'column' : 'row'}>
                      <SimpleSelect
                        autoFocus={true}
                        onChange={(
                          _e: React.SyntheticEvent<Element, Event>,
                          data: {value?: string | number | undefined; id?: string | undefined}
                        ) => {
                          setSubstitution(substitution.id, data, 'from')
                        }}
                        renderLabel=""
                        width={matches?.includes('small') ? '100%' : '18.75rem'}
                      >
                        {weekDays.map((d, index) => (
                          <SimpleSelect.Option key={d.key} id={d.key} value={index}>
                            {d.name}
                          </SimpleSelect.Option>
                        ))}
                      </SimpleSelect>
                      <View
                        as="div"
                        width={matches?.includes('small') ? '100%' : '7.5rem'}
                        textAlign={matches?.includes('small') ? 'start' : 'center'}
                        margin={matches?.includes('small') ? 'small 0' : '0'}
                        tabIndex={-1}
                      >
                        {I18n.t('to')}
                      </View>
                      <SimpleSelect
                        onChange={(
                          _e: React.SyntheticEvent<Element, Event>,
                          data: {value?: string | number | undefined; id?: string | undefined}
                        ) => {
                          setSubstitution(substitution.id, data, 'to')
                        }}
                        renderLabel=""
                        width={matches?.includes('small') ? '100%' : '18.75rem'}
                      >
                        {weekDays.map((d, index) => (
                          <SimpleSelect.Option key={d.key} id={d.key} value={index}>
                            {d.name}
                          </SimpleSelect.Option>
                        ))}
                      </SimpleSelect>
                      <IconButton
                        withBorder={false}
                        withBackground={false}
                        onClick={() => {
                          const tmp = JSON.parse(JSON.stringify(dateAdjustments))
                          tmp.date_shift_options.day_substitutions =
                            tmp.date_shift_options.day_substitutions.filter(
                              (sub: DaySub) => sub.id !== substitution.id
                            )
                          setDateAdjustments(tmp)
                        }}
                        screenReaderLabel={I18n.t("Remove '%{from}' to '%{to}' from substitutes", {
                          to: weekDays[substitution.to].name,
                          from: weekDays[substitution.from].name,
                        })}
                      >
                        {matches?.includes('small') ? (
                          <Text color="danger">{I18n.t('Remove')}</Text>
                        ) : (
                          <IconEndLine />
                        )}
                      </IconButton>
                    </Flex>
                  </View>
                ))}
                <Button
                  margin="medium none none none"
                  onClick={() => {
                    const tmp = JSON.parse(JSON.stringify(dateAdjustments))
                    tmp.date_shift_options.day_substitutions.push({from: 0, to: 0, id: subs_id++})
                    setDateAdjustments(tmp)
                  }}
                  color="secondary"
                  width={matches?.includes('small') ? '100%' : '8.5rem'}
                >
                  <PresentationContent>
                    <IconAddLine /> {I18n.t('Substitution')}
                  </PresentationContent>
                  <ScreenReaderContent>{I18n.t('Add substitution')}</ScreenReaderContent>
                </Button>
              </>
            ) : null}
          </View>
        )
      }}
    </Responsive>
  )
}

export default DateAdjustments

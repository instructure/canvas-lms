/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import React, {useEffect, useRef, useState} from 'react'
import {connect} from 'react-redux'
import {Flex} from '@instructure/ui-flex'
import CanvasDateInput2 from '@canvas/datetime/react/components/DateInput2'
import {coursePaceTimezone} from '../../shared/api/backend_serializer'
import * as tz from '@instructure/moment-utils'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import {NumberInput} from '@instructure/ui-number-input'
import {View} from '@instructure/ui-view'
import moment from 'moment-timezone'
import _ from 'lodash'
import type {CoursePace, OptionalDate, Pace, ResponsiveSizes, StoreState} from '../../types'
import {generateDatesCaptions, rawDaysBetweenInclusive} from '../../utils/date_stuff/date_helpers'
import {coursePaceActions} from '../../actions/course_paces'
import {calendarDaysToPaceDuration} from '../../utils/utils'
import {getBlackoutDates} from '../../shared/reducers/blackout_dates'
import {BlackoutDate} from '../../shared/types'

const I18n = createI18nScope('acceptable_use_policy')

const GAP_WIDTH = 'medium'

interface PassedProps {
  readonly coursePace: CoursePace
  readonly appliedPace: Pace
  readonly responsiveSize: ResponsiveSizes
}

interface StoreProps {
  readonly blackoutDates: BlackoutDate[]
}

interface DispatchProps {
  readonly setTimeToCompleteCalendarDays: typeof coursePaceActions.setTimeToCompleteCalendarDays
  readonly setPaceItemsDurationFromTimeToComplete: typeof coursePaceActions.setPaceItemsDurationFromTimeToComplete
  readonly setStartDate: typeof coursePaceActions.setStartDate
  readonly setTimeToCompleteCalendarDaysFromItems: typeof coursePaceActions.setTimeToCompleteCalendarDaysFromItems
}

interface DateInputWithCaptionProps {
  date: OptionalDate
  dateColumnWidth: string
  onChangeDate: (date: string) => void
  caption: string
  renderLabel: string
  dataTestId: string
  disabledDates: (isoDateToCheck: string) => boolean
}

interface NumberInputWithLabelProps {
  value: number
  label: string
  renderLabel: string
  unit: 'weeks' | 'days'
  dataTestId: string
}

const formatDate = (date: Date) => {
  return tz.format(date, 'date.formats.long') || ''
}

const DateInputContainer = ({
  children,
  caption,
  dateColumnWidth,
}: {children: React.ReactNode; caption: string; dateColumnWidth: string}) => {
  return (
    <Flex.Item width={dateColumnWidth} padding="xxx-small 0 0 0">
      {children}
      <View margin="small 0 0 0" display="inline-block">
        <Text size="small">{caption}</Text>
      </View>
    </Flex.Item>
  )
}

const DateInputWithCaption = ({
  date,
  dateColumnWidth,
  onChangeDate,
  caption,
  renderLabel,
  dataTestId,
  disabledDates,
}: DateInputWithCaptionProps) => {
  const onChange = (selectedDate: Date | null) => {
    if (selectedDate === null) return
    const dateValue = selectedDate.toISOString()
    if (dateValue === date) return
    onChangeDate(dateValue)
  }

  return (
    <DateInputContainer caption={caption} dateColumnWidth={dateColumnWidth}>
      <CanvasDateInput2
        renderLabel={renderLabel}
        timezone={coursePaceTimezone}
        formatDate={formatDate}
        selectedDate={date}
        onSelectedDateChange={onChange}
        width={dateColumnWidth}
        isInline={false}
        withRunningValue={true}
        interaction={undefined}
        dataTestid={dataTestId}
        disabledDates={disabledDates}
      />
    </DateInputContainer>
  )
}

type TimeSelectionProps = PassedProps & StoreProps & DispatchProps

const TimeSelection = (props: TimeSelectionProps) => {
  const {
    coursePace,
    appliedPace,
    setTimeToCompleteCalendarDays,
    responsiveSize,
    setPaceItemsDurationFromTimeToComplete,
    blackoutDates,
    setStartDate,
    setTimeToCompleteCalendarDaysFromItems,
  } = props

  const originalSelectedDaysToSkip = useRef(coursePace.selected_days_to_skip)
  const originalBlackoutDates = useRef(blackoutDates)

  const enrollmentType = coursePace.context_type === 'Enrollment'
  const dateColumnWidth = responsiveSize === 'small' ? '100%' : '15.313rem'

  const [endDate, setEndDate] = useState<OptionalDate>(null)
  const [weeks, setWeeks] = useState<number>(0)
  const [days, setDays] = useState<number>(0)

  useEffect(() => {
    if (
      !_.isEqual(coursePace.selected_days_to_skip, originalSelectedDaysToSkip.current) ||
      !_.isEqual(blackoutDates, originalBlackoutDates.current)
    ) {
      setTimeToCompleteCalendarDaysFromItems(blackoutDates)
      originalSelectedDaysToSkip.current = coursePace.selected_days_to_skip
      originalBlackoutDates.current = blackoutDates
    }
  }, [coursePace.selected_days_to_skip, blackoutDates, setTimeToCompleteCalendarDaysFromItems])

  useEffect(() => {
    const startDateMoment = moment(coursePace.start_date).startOf('day')
    const calendarDays =
      coursePace.time_to_complete_calendar_days === 0
        ? 0
        : coursePace.time_to_complete_calendar_days || 0
    const endDateValue = startDateMoment.add(calendarDays, 'days').startOf('day').toISOString()
    setEndDate(endDateValue)

    const originalPaceDuration = calendarDaysToPaceDuration(
      coursePace.time_to_complete_calendar_days || 0,
    )
    setWeeks(originalPaceDuration.weeks)
    setDays(originalPaceDuration.days)
  }, [coursePace.time_to_complete_calendar_days, coursePace.start_date])

  const setTimeToComplete = (startDate: OptionalDate, endDate: OptionalDate) => {
    if (!startDate || !endDate) return

    const startDateValue = moment(startDate).endOf('day')
    const endDateValue = moment(endDate).endOf('day')

    const calendarDays = rawDaysBetweenInclusive(startDateValue, endDateValue)
    const calendarDaysValue = calendarDays < 0 ? 0 : calendarDays - 1

    const paceDuration = calendarDaysToPaceDuration(calendarDaysValue)
    setWeeks(paceDuration.weeks)
    setDays(paceDuration.days)

    setTimeToCompleteCalendarDays(calendarDaysValue)
    setPaceItemsDurationFromTimeToComplete(blackoutDates, calendarDaysValue)
  }

  const onChangeStartDate = (dateValue: string) => {
    setStartDate(dateValue)
    setTimeToComplete(dateValue, endDate)
  }

  const onChangeEndDate = (dateValue: string) => {
    setEndDate(dateValue)
    setTimeToComplete(coursePace.start_date, dateValue)
  }

  const captions = generateDatesCaptions(coursePace, coursePace.start_date, endDate, appliedPace)

  const ReadOnlyDateWithCaption = ({
    dateValue,
    caption,
    dataTestId,
  }: {
    dateValue: OptionalDate
    caption: string
    dataTestId: string
  }) => {
    return (
      <LabeledComponent label={I18n.t('Start Date')}>
        <DateInputContainer caption={caption} dateColumnWidth={dateColumnWidth}>
          <View display="inline-block" height="2.406rem" padding="x-small 0 0 x-small">
            <Text data-testid={dataTestId}>
              {formatDate(moment.tz(dateValue, coursePaceTimezone).toDate())}
            </Text>
          </View>
        </DateInputContainer>
      </LabeledComponent>
    )
  }

  const LabeledComponent = ({label, children}: {label: string; children: React.ReactNode}) => {
    return (
      <Flex direction="column">
        <Flex.Item>
          <Text weight="bold">{label}</Text>
        </Flex.Item>
        <Flex
          gap="small"
          direction={responsiveSize === 'small' ? 'column' : 'row'}
          padding="x-small 0 0 0"
        >
          {children}
        </Flex>
      </Flex>
    )
  }

  const NumberInputWithLabel = ({
    value,
    label,
    renderLabel,
    unit,
    dataTestId,
  }: NumberInputWithLabelProps) => {
    const updateEndDate = (operation: 'add' | 'subtract') => {
      if (!Number.isInteger(value) || (value <= 0 && operation === 'subtract')) return

      const newEndDate =
        operation === 'add' ? moment(endDate).add(1, unit) : moment(endDate).subtract(1, unit)

      setEndDate(newEndDate.toISOString(true))
      setTimeToComplete(coursePace.start_date, newEndDate.toISOString(true))
    }

    const onIncrement = () => {
      updateEndDate('add')
    }

    const onDecrement = () => {
      updateEndDate('subtract')
    }

    return (
      <Flex.Item>
        <NumberInput
          renderLabel={renderLabel}
          display={'inline-block'}
          width={responsiveSize === 'small' ? '14.313rem' : '5.313rem'}
          onIncrement={onIncrement}
          onDecrement={onDecrement}
          placeholder={label}
          showArrows={true}
          value={value}
          data-testid={dataTestId}
        />
        <View margin="none none none small">
          <Text>{label}</Text>
        </View>
      </Flex.Item>
    )
  }

  return (
    <View>
      <Flex
        data-testid="time-selection-section"
        gap={GAP_WIDTH}
        direction={responsiveSize === 'small' ? 'column' : 'row'}
        margin="0 0 medium"
        padding="x-small 0 0 xx-small"
        alignItems="start"
      >
        {enrollmentType ? (
          <ReadOnlyDateWithCaption
            dateValue={coursePace.start_date}
            caption={captions.startDate}
            dataTestId="start-date-readonly"
          />
        ) : (
          <DateInputWithCaption
            key="start-date"
            date={coursePace.start_date}
            dateColumnWidth={dateColumnWidth}
            onChangeDate={onChangeStartDate}
            caption={captions.startDate}
            renderLabel={I18n.t('Start Date')}
            dataTestId="start-date-input"
            disabledDates={(date: string) => Boolean(endDate && date > endDate)}
          />
        )}
        <DateInputWithCaption
          key="end-date"
          date={endDate}
          dateColumnWidth={dateColumnWidth}
          onChangeDate={onChangeEndDate}
          caption={captions.endDate}
          renderLabel={I18n.t('End Date')}
          dataTestId="end-date-input"
          disabledDates={(date: string) =>
            Boolean(coursePace.start_date && date < coursePace.start_date)
          }
        />
        <Flex.Item>
          <LabeledComponent label={I18n.t('Time to Complete Course')}>
            <NumberInputWithLabel
              value={weeks}
              label="Weeks"
              renderLabel=""
              unit="weeks"
              dataTestId="weeks-number-input"
            />
            <NumberInputWithLabel
              value={days}
              label="Days"
              renderLabel=""
              unit="days"
              dataTestId="days-number-input"
            />
          </LabeledComponent>
        </Flex.Item>
      </Flex>
    </View>
  )
}

const mapStateToProps = (state: StoreState): StoreProps => {
  return {
    blackoutDates: getBlackoutDates(state),
  }
}

export default connect(mapStateToProps, {
  setTimeToCompleteCalendarDays: coursePaceActions.setTimeToCompleteCalendarDays,
  setPaceItemsDurationFromTimeToComplete: coursePaceActions.setPaceItemsDurationFromTimeToComplete,
  setStartDate: coursePaceActions.setStartDate,
  setTimeToCompleteCalendarDaysFromItems: coursePaceActions.setTimeToCompleteCalendarDaysFromItems,
})(TimeSelection)

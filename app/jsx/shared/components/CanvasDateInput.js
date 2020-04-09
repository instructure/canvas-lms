/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import I18n from 'i18n!app_shared_components_canvas_date_time'
import React, {useEffect, useRef, useState} from 'react'
import {arrayOf, element, func, instanceOf, oneOfType, shape, string} from 'prop-types'
import moment from 'moment-timezone'
import tz from 'timezone'
import {DateTime} from '@instructure/ui-i18n'
import {AccessibleContent} from '@instructure/ui-a11y-content'
import {Calendar} from '@instructure/ui-calendar'
import {DateInput} from '@instructure/ui-date-input'
import {IconButton} from '@instructure/ui-buttons'
import {IconArrowOpenEndSolid, IconArrowOpenStartSolid} from '@instructure/ui-icons'

// This depends on moment's default locale being set and on ENV.TIMEZONE.

CanvasDateInput.propTypes = {
  selectedDate: instanceOf(Date), // may be null for no selected date
  renderLabel: oneOfType([element, string, func]),
  messages: arrayOf(shape({type: string, text: string})),
  timezone: string,
  formatDate: func.isRequired,
  onSelectedDateChange: func.isRequired,
  interaction: string
}

CanvasDateInput.defaultProps = {
  timezone: ENV?.TIMEZONE || DateTime.browserTimeZone(),
  renderLabel: I18n.t('Choose a date'),
  messages: [],
  interaction: 'enabled'
}

export default function CanvasDateInput({
  selectedDate,
  renderLabel,
  messages,
  timezone,
  formatDate,
  onSelectedDateChange,
  interaction
}) {
  const todayMoment = moment().tz(timezone)
  const selectedMoment = selectedDate && moment.tz(selectedDate, timezone)

  const priorSelectedMoment = useRef(null)
  useEffect(() => {
    priorSelectedMoment.current = selectedMoment
  })

  const [inputValue, setInputValue] = useState('')
  const [inputDirty, setInputDirty] = useState(false)
  const [isShowingCalendar, setIsShowingCalendar] = useState(false)
  const [renderedMoment, setRenderedMoment] = useState(selectedMoment || todayMoment)
  const [errorMessages, setErrorMessages] = useState([])

  const selectedMomentChangedNull =
    (selectedMoment === null && priorSelectedMoment.current !== null) ||
    (selectedMoment !== null && priorSelectedMoment.current === null)
  const selectedMomentChangedValue =
    selectedMoment && !selectedMoment.isSame(priorSelectedMoment.current)
  if (!inputDirty && (selectedMomentChangedNull || selectedMomentChangedValue)) {
    syncInput(selectedMoment)
  }

  function syncInput(newMoment) {
    const newInputValue = newMoment ? formatDate(newMoment.toDate()) : ''
    if (inputValue !== newInputValue) {
      setInputValue(newInputValue)
      setInputDirty(false)
      setRenderedMoment(newMoment || todayMoment)
      setErrorMessages([])
    }
  }

  function generateMonthMoments() {
    const firstMoment = moment
      .tz(renderedMoment, timezone)
      .startOf('month')
      .startOf('week')
    return [...Array(Calendar.DAY_COUNT).keys()].map(index =>
      firstMoment.clone().add(index, 'days')
    )
  }

  function renderDays() {
    // This is expensive, so only do it if the calendar is open
    if (!isShowingCalendar) return null
    const days = generateMonthMoments().map(dayMoment => (
      <DateInput.Day
        key={dayMoment.toISOString()}
        date={dayMoment.toISOString(true)}
        label={tz.format(dayMoment.toDate(), 'date.formats.medium')}
        isSelected={dayMoment.isSame(selectedMoment, 'day')}
        isToday={dayMoment.isSame(todayMoment, 'day')}
        isOutsideMonth={!dayMoment.isSame(renderedMoment, 'month')}
        onClick={handleDayClick}
      >
        {dayMoment.format('D')}
      </DateInput.Day>
    ))
    return days
  }

  function handleChange(_event, {value}) {
    setInputValue(value)
    setInputDirty(true)
    const newDate = tz.parse(value)
    if (newDate) setRenderedMoment(moment.tz(newDate, timezone))
    onSelectedDateChange(newDate)
  }

  function handleDayClick(_event, {date}) {
    const parsedMoment = moment.tz(date, timezone)
    syncInput(parsedMoment)
    onSelectedDateChange(parsedMoment.toDate())
  }

  function handleValidateDate() {
    if (!selectedMoment && inputValue) {
      setErrorMessages([{type: 'error', text: I18n.t("That's not a date!")}])
    }
  }

  function handleBlur() {
    if (selectedMoment) {
      syncInput(selectedMoment)
    }
  }

  function handleHideCalendar() {
    setIsShowingCalendar(false)
    if (selectedMoment) syncInput(selectedMoment)
  }

  function modifySelectedMoment(step, type) {
    // If we do not have a selectedMoment, we'll just select the first day of
    // the currently rendered month.
    const newMoment = selectedMoment
      ? selectedMoment.clone().add(step, type)
      : renderedMoment.clone().startOf('month')

    syncInput(newMoment)
    onSelectedDateChange(newMoment.toDate())
  }

  function modifyRenderedMoment(step, type) {
    setRenderedMoment(renderedMoment.clone().add(step, type))
  }

  function renderWeekdayLabels() {
    const firstOfWeek = renderedMoment.clone().startOf('week')
    return [...Array(7).keys()].map(index => {
      const thisDay = firstOfWeek.clone().add(index, 'days')
      return (
        <AccessibleContent alt={thisDay.format('dddd')}>{thisDay.format('dd')}</AccessibleContent>
      )
    })
  }

  function renderMonthChangeButton(direction) {
    const icon =
      direction === 'prev' ? (
        <IconArrowOpenStartSolid color="primary" />
      ) : (
        <IconArrowOpenEndSolid color="primary" />
      )
    const label = direction === 'prev' ? I18n.t('Previous month') : I18n.t('Next month')
    return (
      <IconButton
        size="small"
        withBackground={false}
        withBorder={false}
        renderIcon={icon}
        screenReaderLabel={label}
      />
    )
  }

  return (
    <DateInput
      renderLabel={renderLabel}
      assistiveText={I18n.t('Type a date or use arrow keys to navigate date picker.')}
      value={inputValue}
      onChange={handleChange}
      isInline
      messages={messages.concat(errorMessages)}
      isShowingCalendar={isShowingCalendar}
      onBlur={handleBlur}
      onRequestValidateDate={handleValidateDate}
      onRequestShowCalendar={() => setIsShowingCalendar(true)}
      onRequestHideCalendar={handleHideCalendar}
      onRequestSelectNextDay={() => modifySelectedMoment(1, 'day')}
      onRequestSelectPrevDay={() => modifySelectedMoment(-1, 'day')}
      onRequestRenderNextMonth={() => modifyRenderedMoment(1, 'month')}
      onRequestRenderPrevMonth={() => modifyRenderedMoment(-1, 'month')}
      renderNavigationLabel={
        <span>
          <div>{renderedMoment.format('MMMM')}</div>
          <div>{renderedMoment.format('YYYY')}</div>
        </span>
      }
      renderPrevMonthButton={renderMonthChangeButton('prev')}
      renderNextMonthButton={renderMonthChangeButton('next')}
      renderWeekdayLabels={renderWeekdayLabels()}
      interaction={interaction}
    >
      {renderDays()}
    </DateInput>
  )
}

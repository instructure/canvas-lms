/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import React, {useState, useEffect, useLayoutEffect, useCallback, useRef} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {TextInput} from '@instructure/ui-text-input'
import {Flex} from '@instructure/ui-flex'
import {SimpleSelect} from '@instructure/ui-simple-select'
import CanvasDateInput from '@canvas/datetime/react/components/DateInput'
import {TimeSelect} from '@instructure/ui-time-select'
import {Checkbox} from '@instructure/ui-checkbox'
import {FormField, FormFieldGroup} from '@instructure/ui-form-field'
import {IconInfoLine} from '@instructure/ui-icons'
import {Spinner} from '@instructure/ui-spinner'
import {Tooltip} from '@instructure/ui-tooltip'
import {Button, IconButton} from '@instructure/ui-buttons'
import CalendarConferenceWidget from '@canvas/calendar-conferences/react/CalendarConferenceWidget'
import filterConferenceTypes from '@canvas/calendar-conferences/filterConferenceTypes'
import getConferenceType from '@canvas/calendar-conferences/getConferenceType'
import * as tz from '@canvas/datetime'
import moment from 'moment'
import commonEventFactory from '@canvas/calendar/jquery/CommonEvent/index'
import fcUtil from '@canvas/calendar/jquery/fcUtil'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import useDateTimeFormat from '@canvas/use-date-time-format-hook'
import {DateTime} from '@instructure/ui-i18n'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {
  updateRRuleForNewDate,
  RRULEToFrequencyOptionValue,
} from '@canvas/calendar/react/RecurringEvents/FrequencyPicker/utils'
import {renderUpdateCalendarEventDialog} from '@canvas/calendar/react/RecurringEvents/UpdateCalendarEventDialog'
import FrequencyPicker from '@canvas/calendar/react/RecurringEvents/FrequencyPicker/FrequencyPicker'
import {encodeQueryString} from '@canvas/query-string-encoding'

const I18n = useI18nScope('calendar.edit_calendar_event')

const screenReaderMessageCallback = msg => {
  showFlashAlert({message: msg, type: 'info', srOnly: true})
}

const hasFormErrors = errors => Object.keys(errors).some(key => errors[key])

const CalendarEventDetailsForm = ({event, closeCB, contextChangeCB, setSetContextCB, timezone}) => {
  timezone = timezone || ENV?.TIMEZONE || DateTime.browserTimeZone()
  const locale = ENV?.MOMENT_LOCALE || ENV?.LOCALE || 'en'

  const initTime = time => (!time || event.allDay ? '' : time)
  const today = moment().tz(timezone)

  const [title, setTitle] = useState(event.title || '')
  const [context, setContext] = useState(event.contextInfo || event.allPossibleContexts[0])
  const [location, setLocation] = useState(event.location_name || '')
  const [date, setDate] = useState(tz.parse(event.startDate().format('YYYY-MM-DD'), timezone))
  const [startTime, setStartTime] = useState(initTime(event.calendarEvent?.start_at))
  const [endTime, setEndTime] = useState(initTime(event.calendarEvent?.end_at))
  const [rrule, setRRule] = useState(event.object.rrule ? event.object.rrule : null)
  const [frequency, setFrequency] = useState(
    rrule ? RRULEToFrequencyOptionValue(moment.tz(date, timezone), rrule) : null
  )
  const [webConference, setWebConference] = useState(event.webConference)
  const [shouldShowConferences, setShouldShowConferences] = useState(false)
  const [isImportant, setImportant] = useState(event.important_dates)
  const [isBlackout, setBlackout] = useState(event.blackout_date)
  const [startMessages, setStartMessages] = useState([])
  const [endMessages, setEndMessages] = useState([])
  const [firstRender, setFirstRender] = useState(true)
  const [isWorking, setIsWorking] = useState(false)
  const [formErrors, setFormErrors] = useState(() => ({
    title: title.trim().length === 0,
    date: !moment.tz(date, timezone).isValid(),
  }))

  const hasChanged = useRef(false)

  const allContexts = event.allPossibleContexts

  const shouldEnableTimeFields = () => !isBlackout
  // Right now we don't have a way to edit event series and backend doesn't support to change
  // the rrule of an event. Also we don't save frequency in database.
  const shouldShowLocationField = () => event.calendarEvent?.parent_event_id == null
  const shouldEnableLocationField = () => !isBlackout
  const shouldShowConferenceField = () => shouldShowConferences
  const shouldEnableConferenceField = () => !isBlackout
  const shouldShowContextField = () => event.can_change_context
  const shouldShowImportantDatesField = () => context.k5_course || context.k5_account
  const shouldShowBlackoutDateCheckbox = useCallback(() => {
    return (
      ENV.FEATURES.account_level_blackout_dates &&
      (context.type === 'account' || (context.type === 'course' && context.course_pacing_enabled))
    )
  }, [context])

  const getMoreOptionsHref = useCallback(() => {
    // Update the edit and more option urls
    if (event.isNewEvent()) {
      return context.new_calendar_event_url
    } else {
      return `${event.fullDetailsURL()}/edit`
    }
  }, [context, event])

  const onContextChange = useCallback(
    propagate => {
      if (context == null) return

      event.contextInfo = context
      if (!shouldShowBlackoutDateCheckbox()) setBlackout(false)

      if (propagate !== false) contextChangeCB(context.asset_string)
    },
    [context, event.contextInfo, shouldShowBlackoutDateCheckbox, contextChangeCB]
  )

  const contextFromCode = useCallback(
    code => {
      return allContexts.find(ctxt => ctxt.asset_string === code) || null
    },
    [allContexts]
  )

  const setContextWithCode = useCallback(
    code => {
      setContext(contextFromCode(code))
    },
    [contextFromCode]
  )

  const canUpdateConference = useCallback(() => !event.lockedTitle, [event])

  const getActiveConferenceTypes = useCallback(
    (ctxt = context) => {
      const conferenceTypes = ENV.conferences?.conference_types || []
      const context_code = ctxt.asset_string
      return filterConferenceTypes(conferenceTypes, context_code)
    },
    [context]
  )

  const shouldShowConferenceWidget = useCallback(() => {
    return webConference || (canUpdateConference() && getActiveConferenceTypes().length > 0)
  }, [webConference, canUpdateConference, getActiveConferenceTypes])

  useEffect(() => {
    onContextChange(true)
  }, [context, onContextChange])

  useEffect(() => {
    if (firstRender) {
      setFirstRender(false)
      onContextChange(false)
      setSetContextCB(setContextWithCode)
    }
  }, [firstRender, setFirstRender, onContextChange, setContextWithCode, setSetContextCB])

  useLayoutEffect(() => {
    setShouldShowConferences(shouldShowConferenceWidget())
  }, [context, shouldShowConferenceWidget])

  const changeContext = value => {
    const newContext = contextFromCode(value)

    if (
      canUpdateConference() &&
      webConference &&
      undefined === getConferenceType(getActiveConferenceTypes(newContext), webConference)
    ) {
      setWebConference(null)
    }

    setContext(newContext)
    // After this, the useEffect hook will call onContextChange
  }

  const dateFormatter = useDateTimeFormat('date.formats.medium_with_weekday', timezone)

  const clearMessages = () => {
    setStartMessages([])
    setEndMessages([])
  }

  const trySetStartTime = time => {
    clearMessages()
    if (!time || !endTime || time <= endTime) {
      setStartTime(time)
      if (!endTime && time > moment.tz(timezone).startOf('day').toISOString())
        setEndTime(moment.tz(timezone).endOf('day').toISOString())
    } else setStartMessages([{text: I18n.t('Start Time cannot be after End Time'), type: 'error'}])
  }

  const trySetEndTime = time => {
    clearMessages()
    if (!time || !startTime || startTime <= time) {
      setEndTime(time)
      if (!startTime) setStartTime(moment.tz(timezone).startOf('day').toISOString())
    } else setEndMessages([{text: I18n.t('End time cannot be before Start time'), type: 'error'}])
  }

  const setConference = conference => {
    if (canUpdateConference()) setWebConference(conference)
  }

  const getEventUrlParams = () => {
    const params = {return_to: window.location.href}

    if (title && !event.lockedTitle) params.title = title
    if (context && event.can_change_context) params.new_context_code = context.asset_string
    if (location) params.location_name = location
    if (date) params.start_date = date.toISOString()
    params.start_time = startTime ? moment.tz(startTime, timezone).format('LT') : ''
    params.end_time = endTime ? moment.tz(endTime, timezone).format('LT') : ''
    params.important_dates = isImportant
    params.blackout_date = isBlackout
    params.context_type = context.type
    params.course_pacing_enabled = context.course_pacing_enabled
    params.calendar_event_context_code = event.calendarEvent?.context_code
    if (typeof rrule === 'string') {
      params.rrule = rrule
    }

    if (canUpdateConference()) {
      if (webConference) {
        params.web_conference = webConference
      } else {
        params.web_conference = ''
      }
    }
    return params
  }

  const buildEditEventUrl = extraParams => {
    const moreOptionsUrl = new URL(getMoreOptionsHref(), window.location.origin)
    const queryString = encodeQueryString({...getEventUrlParams(), ...extraParams})
    if (moreOptionsUrl.search) {
      moreOptionsUrl.search += `&${queryString}`
    } else {
      moreOptionsUrl.search = `?${queryString}`
    }
    return moreOptionsUrl.toString()
  }

  const moreOptionsClick = jsEvent => {
    jsEvent?.preventDefault()

    window.location.href = buildEditEventUrl().toString()
  }

  const handleFrequencyChange = useCallback((newFrequency, newRRule) => {
    if (newFrequency !== 'custom') {
      setRRule(newRRule)
    }
    setFrequency(newFrequency)
  }, [])

  const handleDateChange = useCallback(
    (d, dateInputType) => {
      setDate(d)
      setFormErrors({...formErrors, date: dateInputType === 'error'})
      if (rrule === null || frequency === 'saved-custom') return
      const newRRule = updateRRuleForNewDate(moment.tz(d, timezone), rrule)
      setRRule(newRRule)
    },
    [frequency, rrule, timezone, formErrors]
  )

  const addTimeToDate = time => {
    // dateTime is set to the correct date but the incorrect time
    // momentTime is set to the correct time but the incorrect date
    // Setting the momentTime's date to the dateTime's date will give us the correct date and time. This will handle
    // DST issues as well since the momentTime will be set to the correct time in the correct timezone.
    const dateTime = moment.tz(date, timezone)
    if (!time) return dateTime

    const momentTime = moment.tz(time, timezone)
    momentTime.set('year', dateTime.year())
    momentTime.set('month', dateTime.month())
    momentTime.set('date', dateTime.date())
    return momentTime
  }

  const formSubmit = async jsEvent => {
    jsEvent.preventDefault()

    const startAt = addTimeToDate(startTime)
    const endAt = addTimeToDate(endTime)

    const params = {
      'calendar_event[title]': title != null ? title : event.title,
      'calendar_event[start_at]':
        startAt && shouldEnableTimeFields() ? startAt.toISOString() : date.toISOString(),
      'calendar_event[end_at]':
        endAt && shouldEnableTimeFields() ? endAt.toISOString() : date.toISOString(),
      'calendar_event[location_name]': location && shouldEnableLocationField() ? location : '',
      'calendar_event[important_dates]': isImportant,
      'calendar_event[blackout_date]': isBlackout,
    }

    params['calendar_event[rrule]'] = rrule

    if (canUpdateConference()) {
      if (webConference && shouldEnableConferenceField()) {
        const webConf = {
          ...webConference,
          title:
            webConference.conference_type !== 'LtiConference'
              ? params['calendar_event[title]']
              : webConference.title,
          user_settings: {
            ...webConference.user_settings,
            scheduled_date: params['calendar_event[start_at]'],
          },
        }
        const conferenceParams = new URLSearchParams(
          encodeQueryString({
            calendar_event: {
              web_conference: webConf,
            },
          })
        )
        for (const [key, value] of conferenceParams.entries()) {
          params[key] = value
        }
      } else {
        params['calendar_event[web_conference]'] = ''
      }
    }

    if (event.isNewEvent()) {
      params['calendar_event[context_code]'] = context.asset_string
      if (rrule) params['calendar_event[rrule]'] = rrule
      const objectData = {
        calendar_event: {
          title: params['calendar_event[title]'],
          start_at: startAt && shouldEnableTimeFields() ? startAt.toISOString() : null,
          end_at: endAt && shouldEnableTimeFields() ? endAt.toISOString() : null,
          location_name: shouldEnableLocationField() ? location : null,
          context_code: context.asset_string,
          webConference: shouldEnableConferenceField() ? webConference : null,
          important_info: isImportant,
          blackout_date: isBlackout,
        },
      }
      const newEvent = commonEventFactory(objectData, event.possibleContexts())
      newEvent.save(
        params,
        () => {
          screenReaderMessageCallback(I18n.t('The event was successfully created'))
          closeCB()
        },
        () => {
          screenReaderMessageCallback(I18n.t('Event creation failed'))
          closeCB()
        }
      )
    } else {
      event.title = params['calendar_event[title]']
      // event unfudges/unwraps values when sending to server (so wrap here)
      event.start = shouldEnableTimeFields() ? fcUtil.wrap(startAt) : fcUtil.wrap(date)
      event.end = shouldEnableTimeFields() ? fcUtil.wrap(endAt) : fcUtil.wrap(date)
      event.location_name = shouldEnableLocationField() ? location : null
      event.webConference = shouldEnableConferenceField() ? webConference : null
      event.important_info = isImportant
      event.blackout_date = isBlackout
      if (event.can_change_context) {
        event.old_context_code = event.object.context_code
        event.removeClass(`group_${event.old_context_code}`)
        event.object.context_code = context.asset_string
        event.contextInfo = contextFromCode(context.asset_string)
        params['calendar_event[context_code]'] = context.asset_string
      }

      if (event.calendarEvent?.series_uuid && rrule) {
        const which = await renderUpdateCalendarEventDialog(event)
        if (which === undefined) return
        params.which = which
      }
      event.save(
        params,
        () => {
          screenReaderMessageCallback(I18n.t('The event was successfully updated'))
          closeCB()
        },
        () => {
          closeCB()
        }
      )
    }
    setIsWorking(true)
  }

  return (
    <View as="form" data-testid="calendar-event-form" onSubmit={formSubmit} margin="small">
      <FormFieldGroup description="" rowSpacing="small" vAlign="middle">
        <TextInput
          data-testid="edit-calendar-event-form-title"
          renderLabel={I18n.t('Title')}
          value={title}
          placeholder={I18n.t('Input Event Title...')}
          interaction={event.lockedTitle ? 'disabled' : 'enabled'}
          onChange={(e, value) => {
            hasChanged.current = true
            setTitle(value)
            setFormErrors({...formErrors, title: value.trim().length === 0})
          }}
          messages={
            hasChanged.current && formErrors.title
              ? [{text: I18n.t('errors.title_required', 'You must enter a title.'), type: 'error'}]
              : []
          }
        />
        <CanvasDateInput
          dataTestid="edit-calendar-event-form-date"
          renderLabel={
            <Flex>
              <Flex.Item>
                <Text weight="bold">{I18n.t('Date')}</Text>
              </Flex.Item>
              <Flex.Item>
                <Tooltip
                  renderTip={I18n.t("Default date will be today's date")}
                  placement="top"
                  on={['hover', 'focus']}
                >
                  <IconButton
                    renderIcon={IconInfoLine}
                    withBackground={false}
                    withBorder={false}
                    size="small"
                    shape="circle"
                    screenReaderLabel={I18n.t("Default date will be today's date")}
                  />
                </Tooltip>
              </Flex.Item>
            </Flex>
          }
          selectedDate={date?.toISOString()}
          formatDate={dateFormatter}
          onSelectedDateChange={handleDateChange}
          width="100%"
          display="block"
          timezone={timezone}
          defaultToToday={true}
          invalidDateMessage={I18n.t('This date is invalid.')}
        />
        <Flex justifyItems="space-between" alignItems="start">
          <Flex.Item padding="none small none none" shouldShrink={true}>
            <TimeSelect
              disabled={!shouldEnableTimeFields()}
              data-testid="event-form-start-time"
              renderLabel={I18n.t('From')}
              value={shouldEnableTimeFields() ? startTime : ''}
              placeholder={I18n.t('Start Time')}
              onChange={(e, {value}) => trySetStartTime(value)}
              onBlur={clearMessages}
              messages={startMessages}
              format="LT"
              timezone={timezone}
              step={15}
              allowNonStepInput={true}
            />
          </Flex.Item>
          <Flex.Item padding="none none none small" shouldShrink={true}>
            <TimeSelect
              disabled={!shouldEnableTimeFields()}
              data-testid="event-form-end-time"
              renderLabel={I18n.t('To')}
              value={shouldEnableTimeFields() ? endTime : ''}
              placeholder={I18n.t('End Time')}
              onChange={(e, {value}) => trySetEndTime(value)}
              onBlur={clearMessages}
              messages={endMessages}
              format="LT"
              timezone={timezone}
              step={15}
              allowNonStepInput={true}
            />
          </Flex.Item>
        </Flex>
        <FrequencyPicker
          key={date || today}
          date={date || today}
          locale={locale}
          timezone={timezone}
          width="auto"
          initialFrequency={frequency}
          rrule={rrule}
          onChange={(newFrequency, newRRule) => handleFrequencyChange(newFrequency, newRRule)}
          courseEndAt={context.course_conclude_at || undefined}
        />
        {shouldShowLocationField() && (
          <TextInput
            data-testid="edit-calendar-event-form-location"
            disabled={!shouldEnableLocationField()}
            renderLabel={I18n.t('Location')}
            value={shouldEnableLocationField() ? location : ''}
            placeholder={I18n.t('Input Event Location...')}
            onChange={(e, value) => setLocation(value)}
          />
        )}
        {shouldShowConferenceField() && (
          <FormField id="edit-calendar-event-form-conferencing" label={I18n.t('Conferencing')}>
            <CalendarConferenceWidget
              disabled={!shouldEnableConferenceField()}
              context={context.asset_string}
              conference={shouldEnableConferenceField() ? webConference : null}
              setConference={setConference}
              conferenceTypes={getActiveConferenceTypes()}
            />
          </FormField>
        )}
        {shouldShowContextField() && (
          <SimpleSelect
            data-testid="edit-calendar-event-form-context"
            renderLabel={I18n.t('Calendar')}
            assistiveText={I18n.t('Use arrow keys to navigate options.')}
            value={context.asset_string}
            onChange={(e, {value}) => changeContext(value)}
          >
            {allContexts
              .filter(ctxt => ctxt.can_create_calendar_events)
              .map((ctxt, index) => (
                <SimpleSelect.Option
                  key={ctxt.asset_string}
                  id={`opt-${index}`}
                  value={ctxt.asset_string}
                  renderLabel={ctxt.name}
                >
                  {ctxt.name}
                </SimpleSelect.Option>
              ))}
          </SimpleSelect>
        )}
        {shouldShowImportantDatesField() && (
          <FormField id="k5-field" label={I18n.t('Important Dates:')}>
            <Flex justifyItems="space-between">
              <Flex.Item padding="none x-small" shouldShrink={true}>
                <Checkbox
                  data-testid="calendar-event-important-dates"
                  label={I18n.t('Mark as Important Date')}
                  checked={isImportant}
                  onChange={e => setImportant(e.currentTarget.checked)}
                />
              </Flex.Item>
              <Flex.Item padding="none xxx-small" shouldShrink={true}>
                <Tooltip
                  renderTip={I18n.t('Show event on homeroom sidebar')}
                  on={['click', 'hover', 'focus']}
                >
                  <IconButton
                    renderIcon={IconInfoLine}
                    withBackground={false}
                    withBorder={false}
                    screenReaderLabel={I18n.t('Toggle Tooltip')}
                  />
                </Tooltip>
              </Flex.Item>
            </Flex>
          </FormField>
        )}
        {shouldShowBlackoutDateCheckbox() && (
          <FormField id="course-pacing-field" label={I18n.t('Course Pacing:')}>
            <Flex justifyItems="space-between">
              <Flex.Item padding="none x-small" shouldShrink={true}>
                <Checkbox
                  label={I18n.t('Add to Course Pacing blackout dates')}
                  checked={isBlackout}
                  onChange={e => setBlackout(e.currentTarget.checked)}
                />
              </Flex.Item>
              <Flex.Item padding="none x-small" shouldShrink={true}>
                <Tooltip
                  renderTip={I18n.t(
                    'Enabling this option automatically moves Course Pacing assignment due dates to after the end date. Input for Time, Location and Calendar will be disabled.'
                  )}
                  on={['click', 'hover', 'focus']}
                >
                  <IconButton
                    renderIcon={IconInfoLine}
                    withBackground={false}
                    withBorder={false}
                    screenReaderLabel={I18n.t('Toggle Tooltip')}
                  />
                </Tooltip>
              </Flex.Item>
            </Flex>
          </FormField>
        )}
        <Flex justifyItems="end" margin="medium none none none">
          <Flex.Item padding="none x-small" shouldShrink={true}>
            <Tooltip renderTip={I18n.t('A save is in progress')} on={isWorking ? undefined : []}>
              <Button
                data-testid="edit-calendar-event-more-options-button"
                type="button"
                color="secondary"
                onClick={e => (isWorking ? e.preventDefault() : moreOptionsClick(e))}
              >
                {I18n.t('More Options')}
              </Button>
            </Tooltip>
          </Flex.Item>
          <Flex.Item padding="none xxx-small" shouldShrink={true}>
            <Tooltip renderTip={I18n.t('A save is in progress')} on={isWorking ? undefined : []}>
              <Button
                data-testid="edit-calendar-event-submit-button"
                color="primary"
                onClick={e => {
                  isWorking ? e.preventDefault() : formSubmit(e)
                }}
                type="submit"
                interaction={hasFormErrors(formErrors) ? 'disabled' : 'enabled'}
              >
                {isWorking ? (
                  <Spinner renderTitle={I18n.t('Saving')} size="x-small" />
                ) : (
                  I18n.t('Submit')
                )}
              </Button>
            </Tooltip>
          </Flex.Item>
        </Flex>
      </FormFieldGroup>
    </View>
  )
}

export default CalendarEventDetailsForm

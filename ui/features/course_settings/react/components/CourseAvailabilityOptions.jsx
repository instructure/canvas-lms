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

import {useScope as useI18nScope} from '@canvas/i18n'
import * as tz from '@canvas/datetime'
import moment from 'moment'
import React, {useState} from 'react'
import {bool} from 'prop-types'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Text} from '@instructure/ui-text'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {Checkbox} from '@instructure/ui-checkbox'
import CanvasDateInput from '@canvas/datetime/react/components/DateInput'
import {Flex} from '@instructure/ui-flex'
import {ScreenReaderContent, AccessibleContent} from '@instructure/ui-a11y-content'
import {IconWarningSolid} from '@instructure/ui-icons'
import {changeTimezone} from '@canvas/datetime/changeTimezone'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('CourseAvailabilityOptions')

export default function CourseAvailabilityOptions({canManage, viewPastLocked, viewFutureLocked}) {
  const FORM_IDS = {
    RESTRICT_ENROLLMENTS: 'course_restrict_enrollments_to_course_dates',
    START_DATE: 'course_start_at',
    END_DATE: 'course_conclude_at',
    RESTRICT_FUTURE: 'course_restrict_student_future_view',
    RESTRICT_PAST: 'course_restrict_student_past_view',
  }

  const TERM_DATES = {
    START_DATE:
      window.ENV.STUDENTS_ENROLLMENT_DATES?.start_at || window.ENV.DEFAULT_TERM_DATES?.start_at,
    END_DATE: window.ENV.STUDENTS_ENROLLMENT_DATES?.end_at || window.ENV.DEFAULT_TERM_DATES?.end_at,
  }

  const setFormValue = (id, value) => {
    const field = document.getElementById(id)
    field.value = value
  }

  const getFormValue = id => document.getElementById(id).value

  const [selectedApplicabilityValue, setSelectedApplicabilityValue] = useState(
    getFormValue(FORM_IDS.RESTRICT_ENROLLMENTS) === 'true' ? 'course' : 'term'
  )
  const [startDate, setStartDate] = useState(
    moment(getFormValue(FORM_IDS.START_DATE)).toISOString()
  )
  const [endDate, setEndDate] = useState(moment(getFormValue(FORM_IDS.END_DATE)).toISOString())
  const [restrictBefore, setRestrictBefore] = useState(
    getFormValue(FORM_IDS.RESTRICT_FUTURE) === 'true'
  )
  const [restrictAfter, setRestrictAfter] = useState(
    getFormValue(FORM_IDS.RESTRICT_PAST) === 'true'
  )

  const startDateInputValue =
    selectedApplicabilityValue === 'course' ? startDate : TERM_DATES.START_DATE
  const endDateInputValue = selectedApplicabilityValue === 'course' ? endDate : TERM_DATES.END_DATE

  const datesInteraction = () =>
    canManage && selectedApplicabilityValue === 'course' ? 'enabled' : 'disabled'

  const formatDate = date => tz.format(date, 'date.formats.full')

  const parseDate = (date, tz) => {
    const dateObj = new Date(date)
    const parsedDate = changeTimezone(dateObj, {originTZ: tz, desiredTZ: ENV.TIMEZONE})
    return formatDate(parsedDate)
  }

  const participationExplanationText = () => {
    return selectedApplicabilityValue === 'term'
      ? I18n.t('Course participation is limited to *term* start and end dates.', {
          wrappers: [`<strong>$1</strong>`],
        })
      : I18n.t(
          'Course participation is limited to *course* start and end dates. Any section dates created in the course may override course dates.',
          {
            wrappers: [`<strong>$1</strong>`],
          }
        )
  }

  const clearCourseDates = () => {
    setFormValue(FORM_IDS.START_DATE, null)
    setStartDate(null)
    setFormValue(FORM_IDS.END_DATE, null)
    setEndDate(null)
  }

  return (
    <div className="CourseAvailabilityOptions">
      <FormFieldGroup
        description={
          <ScreenReaderContent>
            {I18n.t('Course Participation and Access Settings')}
          </ScreenReaderContent>
        }
        rowSpacing="small"
        layout="inline"
      >
        <SimpleSelect
          renderLabel={
            <ScreenReaderContent>
              {I18n.t('Limit course participation to term or custom course dates?')}
            </ScreenReaderContent>
          }
          interaction={canManage ? 'enabled' : 'disabled'}
          isInline={true}
          width="350px"
          value={selectedApplicabilityValue}
          onChange={(e, {value}) => {
            if (value !== 'course') {
              // Discard course dates, if they are removed from the Date inputs when Participation is different to course,
              // in order to avoid saving these changes if they are not on the screen at the moment of submitting the form
              clearCourseDates()
            }
            setFormValue(FORM_IDS.RESTRICT_ENROLLMENTS, value === 'course')
            setSelectedApplicabilityValue(value)
          }}
        >
          <SimpleSelect.Option id="term" value="term">
            {I18n.t('Term')}
          </SimpleSelect.Option>
          <SimpleSelect.Option id="course" value="course">
            {I18n.t('Course')}
          </SimpleSelect.Option>
        </SimpleSelect>

        <Text
          size="small"
          weight="light"
          dangerouslySetInnerHTML={{__html: participationExplanationText()}}
        />

        {ENV.COURSE_PACES_ENABLED && (
          <Text size="small" weight="light">
            {I18n.t(
              'Changing the course participation will republish all course pacing with any new dates.'
            )}
          </Text>
        )}

        <>
          <Flex direction="column" display="inline-flex">
            <Flex.Item padding="xx-small">
              <ScreenReaderContent>{I18n.t('Course Start Date')}</ScreenReaderContent>
              <CanvasDateInput
                renderLabel={I18n.t('Start')}
                formatDate={formatDate}
                interaction={datesInteraction()}
                width="16rem"
                selectedDate={startDateInputValue}
                onSelectedDateChange={value => {
                  const start = moment(value).toISOString()
                  setFormValue(FORM_IDS.START_DATE, start)
                  setStartDate(start)
                }}
              />
              {startDateInputValue && (
                <>
                  <View as="div" margin="x-small none xx-small small">
                    <Text size="x-small" weight="light">{`${I18n.t('Local')}: ${parseDate(
                      startDateInputValue,
                      ENV.TIMEZONE
                    )}`}</Text>
                  </View>
                  <View as="div" margin="none none none small">
                    <Text size="x-small" weight="light">{`${I18n.t('Course')}: ${parseDate(
                      startDateInputValue,
                      ENV.CONTEXT_TIMEZONE
                    )}`}</Text>
                  </View>
                </>
              )}
            </Flex.Item>
            <Flex.Item padding="xx-small">
              <ScreenReaderContent>{I18n.t('Course End Date')}</ScreenReaderContent>
              <CanvasDateInput
                renderLabel={I18n.t('End')}
                formatDate={formatDate}
                interaction={datesInteraction()}
                width="16rem"
                selectedDate={endDateInputValue}
                onSelectedDateChange={value => {
                  const end = moment(value).toISOString()
                  setFormValue(FORM_IDS.END_DATE, end)
                  setEndDate(end)
                }}
              />
              {endDateInputValue && (
                <>
                  <View as="div" margin="x-small none xx-small small">
                    <Text size="x-small" weight="light">{`${I18n.t('Local')}: ${parseDate(
                      endDateInputValue,
                      ENV.TIMEZONE
                    )}`}</Text>
                  </View>
                  <View as="div" margin="none none xx-small small">
                    <Text size="x-small" weight="light">{`${I18n.t('Course')}: ${parseDate(
                      endDateInputValue,
                      ENV.CONTEXT_TIMEZONE
                    )}`}</Text>
                  </View>
                </>
              )}
            </Flex.Item>
          </Flex>
          {tz.isMidnight(endDate) && selectedApplicabilityValue === 'course' && (
            <Flex>
              <Flex.Item margin="xx-small small xx-small 0" align="start">
                <AccessibleContent alt={I18n.t('Warning')}>
                  <IconWarningSolid size="x-small" color="warning" />
                </AccessibleContent>
              </Flex.Item>
              <Flex.Item>
                <Text size="small">
                  {I18n.t(
                    'Course participation is set to expire at midnight, so the previous day is the last day this course will be active.'
                  )}
                </Text>
              </Flex.Item>
            </Flex>
          )}
        </>

        <Checkbox
          label={
            selectedApplicabilityValue === 'term'
              ? I18n.t('Restrict students from viewing course before term start date')
              : I18n.t('Restrict students from viewing course before course start date')
          }
          size="small"
          disabled={!canManage || viewFutureLocked}
          checked={restrictBefore}
          onChange={e => {
            setFormValue(FORM_IDS.RESTRICT_FUTURE, e.target.checked)
            setRestrictBefore(e.target.checked)
          }}
        />
        <Checkbox
          label={
            selectedApplicabilityValue === 'term'
              ? I18n.t('Restrict students from viewing course after term end date')
              : I18n.t('Restrict students from viewing course after course end date')
          }
          size="small"
          disabled={!canManage || viewPastLocked}
          checked={restrictAfter}
          onChange={e => {
            setFormValue(FORM_IDS.RESTRICT_PAST, e.target.checked)
            setRestrictAfter(e.target.checked)
          }}
        />
      </FormFieldGroup>
    </div>
  )
}

CourseAvailabilityOptions.propTypes = {
  canManage: bool.isRequired,
  viewPastLocked: bool.isRequired,
  viewFutureLocked: bool.isRequired,
}

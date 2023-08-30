// @ts-nocheck
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

import React, {useEffect, useState} from 'react'
import {connect} from 'react-redux'
import moment from 'moment-timezone'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {PresentationContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

import {coursePaceActions as actions} from '../../../actions/course_paces'
import {StoreState, CoursePace, OptionalDate, PaceDuration} from '../../../types'
import {
  getCoursePace,
  getCoursePaceItems,
  getCompression,
  getPaceDuration,
  getPlannedEndDate,
} from '../../../reducers/course_paces'
import {coursePaceTimezone, coursePaceDateFormatter} from '../../../shared/api/backend_serializer'

const I18n = useI18nScope('course_paces_projected_dates')

const DASH = String.fromCharCode(0x2013)
const NBSP = String.fromCharCode(0x00a0)

const START_DATE_CAPTIONS = {
  user: I18n.t('Student enrollment date'),
  course: I18n.t('Determined by course start date'),
  // always refer to the start and end dates as "course"
  // because the course does whether it's bounded
  // by the term or course dates
  term: I18n.t('Determined by course start date'),
  section: I18n.t('Determined by section start date'),
  hypothetical: I18n.t("Determined by today's date"),
}

const END_DATE_CAPTIONS = {
  hard: I18n.t('Required end date'),
  user: I18n.t('Determined by course pace'),
  course: I18n.t('Determined by course end date'),
  term: I18n.t('Determined by course end date'),
  section: I18n.t('Determined by section end date'),
  hypothetical: I18n.t('Determined by course pace'),
}

type StoreProps = {
  readonly coursePace: CoursePace
  readonly assignments: number
  readonly paceDuration: PaceDuration
  readonly plannedEndDate: OptionalDate
  readonly compressDates: typeof actions.compressDates
  readonly uncompressDates: typeof actions.uncompressDates
  readonly compression: number
}

export const ProjectedDates = ({
  coursePace,
  assignments,
  paceDuration,
  plannedEndDate,
  compressDates,
  uncompressDates,
  compression,
}: StoreProps) => {
  const [dateFormatter] = useState(coursePaceDateFormatter)

  const enrollmentType = coursePace.context_type === 'Enrollment'
  const startDateValue = coursePace.start_date
  const startHelpText = START_DATE_CAPTIONS[coursePace.start_date_context]
  let endDateValue, endHelpText
  if (enrollmentType && !window.ENV.FEATURES.course_paces_for_students) {
    endDateValue = plannedEndDate
    endHelpText = END_DATE_CAPTIONS.user
  } else {
    endDateValue =
      coursePace.end_date_context === 'hypothetical' ? plannedEndDate : coursePace.end_date
    endHelpText = END_DATE_CAPTIONS[coursePace.end_date_context]
  }

  useEffect(() => {
    if (compression > 0) {
      compressDates()
    } else {
      uncompressDates()
    }
  }, [compressDates, compression, uncompressDates])

  const hasAtLeastOneDate = () => !!(startDateValue || endDateValue)

  const renderDate = (label, dateValue, helpText, testid) => {
    return (
      <div data-testid={testid} style={{display: 'inline-block', lineHeight: '1.125rem'}}>
        <View as="div" margin="0">
          <Text weight="bold">{label}</Text>
        </View>
        <View data-testid="coursepace-date-text" as="div" margin="small 0 x-small 0">
          {dateValue ? (
            dateFormatter(moment.tz(dateValue, coursePaceTimezone).toDate())
          ) : (
            <Text>
              {DASH} {I18n.t('Not Specified')} {DASH}
            </Text>
          )}
        </View>
        <div style={{whiteSpace: 'nowrap'}}>
          <Text fontStyle="italic" size="small">
            <span style={{whiteSpace: 'nowrap'}}>{helpText}</span>
          </Text>
        </div>
      </div>
    )
  }

  const renderSummary = () => {
    return (
      <Flex as="section" direction="column" alignItems="end" wrap="wrap">
        <Flex.Item margin="0">
          <View padding="0 xxx-small 0 0" margin="0 x-small 0 0">
            <Text data-testid="number-of-assignments" size="small" fontStyle="italic">
              {I18n.t(
                {
                  one: '1 assignment',
                  other: '%{count} assignments',
                },
                {count: assignments}
              )}
            </Text>
          </View>
          <PresentationContent>
            <Text color="secondary">|</Text>
          </PresentationContent>
          <View margin="0 0 0 x-small">
            <Text data-testid="number-of-weeks" size="small" fontStyle="italic">
              {I18n.t(
                {
                  one: '1 week',
                  other: '%{count} weeks',
                },
                {count: paceDuration.weeks}
              )}
              {NBSP}
              {I18n.t(
                {
                  one: '1 day',
                  other: '%{count} days',
                },
                {count: paceDuration.days}
              )}{' '}
            </Text>
          </View>
        </Flex.Item>
        <Flex.Item margin="0">
          <Text data-testid="dates-shown-time-zone" fontStyle="italic" size="small">
            {I18n.t('Dates shown in course time zone')}
          </Text>
        </Flex.Item>
      </Flex>
    )
  }

  return (
    <div style={{lineHeight: '1.125rem'}}>
      <Flex as="section" alignItems="end" margin="0" wrap="wrap">
        {hasAtLeastOneDate() && (
          <>
            <Flex.Item margin="0 medium medium 0">
              {renderDate(
                I18n.t('Start Date'),
                startDateValue,
                startHelpText,
                'coursepace-start-date'
              )}
            </Flex.Item>
            <Flex.Item margin="0 medium medium 0" shouldGrow={true}>
              {renderDate(I18n.t('End Date'), endDateValue, endHelpText, 'coursepace-end-date')}
            </Flex.Item>
          </>
        )}
        <Flex.Item margin="0 0 x-small 0" shouldGrow={true}>
          {renderSummary()}
        </Flex.Item>
      </Flex>
    </div>
  )
}

const mapStateToProps = (state: StoreState) => {
  return {
    coursePace: getCoursePace(state),
    assignments: getCoursePaceItems(state).length,
    paceDuration: getPaceDuration(state),
    plannedEndDate: getPlannedEndDate(state),
    compression: getCompression(state),
  }
}
export default connect(mapStateToProps, {
  compressDates: actions.compressDates,
  uncompressDates: actions.uncompressDates,
})(ProjectedDates)

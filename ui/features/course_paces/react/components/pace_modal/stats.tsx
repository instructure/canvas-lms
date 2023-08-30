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

import React, {ReactNode, useEffect, useState} from 'react'
import moment from 'moment-timezone'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {
  IconArrowEndLine,
  IconAssignmentLine,
  IconCalendarClockLine,
  IconClockLine,
} from '@instructure/ui-icons'

import {
  coursePaceDateFormatter,
  coursePaceDateShortFormatter,
  coursePaceTimezone,
} from '../../shared/api/backend_serializer'
import {CoursePace, OptionalDate, Pace, PaceDuration, ResponsiveSizes} from '../../types'
import {coursePaceActions} from '../../actions/course_paces'

const I18n = useI18nScope('course_paces_projected_dates')

const DASH = String.fromCharCode(0x2013)

const START_DATE_CAPTIONS = {
  enrollment: I18n.t('Student enrollment date'),
  course: I18n.t('Determined by course start date'),
  section: I18n.t('Determined by section start date'),
  empty: I18n.t("Determined by today's date"),
}

const END_DATE_CAPTIONS = {
  default: I18n.t('Determined by course pace'),
  course: I18n.t('Determined by course end date'),
  section: I18n.t('Determined by section end date'),
  empty: I18n.t('Determined by course pace'),
}

interface PassedProps {
  readonly coursePace: CoursePace
  readonly assignments: number
  readonly paceDuration: PaceDuration
  readonly plannedEndDate: OptionalDate
  readonly compressDates: typeof coursePaceActions.compressDates
  readonly uncompressDates: typeof coursePaceActions.uncompressDates
  readonly compression: number
  readonly responsiveSize: ResponsiveSizes
  readonly appliedPace: Pace
}

export const PaceModalStats = ({
  coursePace,
  assignments,
  paceDuration,
  plannedEndDate,
  compressDates,
  uncompressDates,
  compression,
  responsiveSize,
  appliedPace,
}: PassedProps) => {
  const [dateFormatter, setDateFormat] = useState(coursePaceDateFormatter)
  const [shrink, setShrink] = useState(responsiveSize !== 'large')
  const enrollmentType = coursePace.context_type === 'Enrollment'
  const startDateValue = coursePace.start_date
  let endDateValue
  if (enrollmentType) {
    if (window.ENV.FEATURES.course_paces_for_students) {
      endDateValue = coursePace.end_date || plannedEndDate
    } else {
      endDateValue = plannedEndDate
    }
  } else {
    endDateValue =
      coursePace.end_date_context === 'hypothetical' ? plannedEndDate : coursePace.end_date
  }

  const getStartDateCaption = contextType => {
    if (startDateValue && coursePace.start_date_context !== 'hypothetical') {
      return START_DATE_CAPTIONS[contextType]
    }
    return START_DATE_CAPTIONS.empty
  }
  const getEndDateCaption = contextType => {
    if (endDateValue && coursePace.end_date_context !== 'hypothetical') {
      return END_DATE_CAPTIONS[contextType]
    }
    return END_DATE_CAPTIONS.empty
  }

  const generateDatesCaptions = () => {
    const contextType = coursePace.context_type.toLocaleLowerCase()
    const captions = {startDate: START_DATE_CAPTIONS.empty, endDate: END_DATE_CAPTIONS.empty}
    captions.startDate = getStartDateCaption(contextType)

    if (contextType === 'enrollment') {
      const appliedPaceContextType = appliedPace.type.toLocaleLowerCase()
      const paceType = ['course', 'section'].includes(appliedPaceContextType)
        ? appliedPaceContextType
        : 'default'
      captions.endDate = getEndDateCaption(paceType)
      return captions
    }
    captions.endDate = getEndDateCaption(contextType)
    return captions
  }

  useEffect(() => {
    const isSmallScreen = responsiveSize !== 'large'
    const dateFormat = isSmallScreen ? coursePaceDateShortFormatter : coursePaceDateFormatter
    // @ts-expect-error
    setDateFormat(dateFormat)
    setShrink(isSmallScreen)
  }, [responsiveSize])

  useEffect(() => {
    if (compression > 0) {
      compressDates()
    } else {
      uncompressDates()
    }
  }, [compressDates, compression, uncompressDates])

  const hasAtLeastOneDate = () => !!(startDateValue || endDateValue)

  const getColoredText = (color: string, child: ReactNode, props: any = {}) => (
    <Text color="alert" themeOverride={{alertColor: color}} {...props}>
      {child}
    </Text>
  )

  const renderColoredDate = (label, dateValue, helpText, testid) => {
    return (
      <View data-testid={testid} display="inline-block">
        <View as="div" margin="0">
          {getColoredText('#30203A', label)}
        </View>
        <View data-testid="coursepace-date-text" as="div" margin="xxx-small 0 0 0">
          {dateValue
            ? getColoredText(
                '#66189D',
                dateFormatter(moment.tz(dateValue, coursePaceTimezone).toDate()),
                {weight: 'bold'}
              )
            : getColoredText('#66189D', `${DASH} ${I18n.t('Not Specified')} ${DASH}`, {
                weight: 'bold',
              })}
        </View>
        {!shrink && (
          <div style={{whiteSpace: 'nowrap'}}>
            {getColoredText('#66189D', <span style={{whiteSpace: 'nowrap'}}>{helpText}</span>, {
              fontStyle: 'italic',
              size: 'small',
            })}
          </div>
        )}
      </View>
    )
  }

  const renderDates = () => {
    const captions = generateDatesCaptions()
    return (
      <View
        as="div"
        background="alert"
        themeOverride={{backgroundAlert: '#F9F0FF'}}
        padding="small medium"
        borderRadius="medium"
        height="100%"
      >
        <Flex.Item margin="0 medium medium 0">
          <View
            display="inline-block"
            background="alert"
            themeOverride={{backgroundAlert: '#EAD7F8'}}
            padding="small"
            width="3.3rem"
            height="3.3rem"
            margin="none small none none"
            borderRadius="circle"
          >
            <IconCalendarClockLine
              color="alert"
              size="small"
              themeOverride={{alertColor: '#66189D'}}
            />
          </View>
          {renderColoredDate(
            I18n.t('Start Date'),
            startDateValue,
            captions.startDate,
            'coursepace-start-date'
          )}
        </Flex.Item>
        <Flex.Item margin="0 medium medium 0" shouldGrow={true}>
          <View margin="none small none none">
            <IconArrowEndLine
              color="alert"
              size="x-small"
              themeOverride={{alertColor: '#66189D'}}
            />
          </View>
          {renderColoredDate(
            I18n.t('End Date'),
            endDateValue,
            captions.endDate,
            'coursepace-end-date'
          )}
        </Flex.Item>
      </View>
    )
  }

  const renderAssignmentsSection = () => {
    return (
      <View
        data-testid="colored-assignments-section"
        display="block"
        background="alert"
        themeOverride={{backgroundAlert: '#E7F4FC'}}
        height="100%"
        padding="small medium"
        borderRadius="medium"
        margin={shrink ? 'x-small none' : 'none x-small'}
      >
        <View
          display="inline-block"
          background="alert"
          themeOverride={{backgroundAlert: '#C8E0EF', paddingXSmall: '0.65rem'}}
          padding="x-small small none small"
          width="3.3rem"
          height="3.3rem"
          margin="small small none none"
          borderRadius="circle"
        >
          <IconAssignmentLine color="alert" size="small" themeOverride={{alertColor: '#0374B5'}} />
        </View>
        <View
          data-testid="course-pace-assignment-number"
          display="inline-block"
          margin="small none none none"
        >
          {getColoredText('#30203A', I18n.t('Assignments'))}
          {getColoredText('#0374B5', assignments, {as: 'div', weight: 'bold'})}
        </View>
      </View>
    )
  }

  const renderDurationSection = () => {
    const weeks = I18n.t(
      {
        one: '1 week',
        other: '%{count} weeks',
      },
      {count: paceDuration.weeks}
    )
    const days = I18n.t(
      {
        one: '1 day',
        other: '%{count} days',
      },
      {count: paceDuration.days}
    )

    const duration = `${weeks}, ${days}`
    return (
      <View
        data-testid="colored-duration-section"
        display="block"
        background="alert"
        themeOverride={{backgroundAlert: '#E3FFF2'}}
        height="100%"
        padding="small medium"
        borderRadius="medium"
      >
        <View
          display="inline-block"
          background="alert"
          themeOverride={{backgroundAlert: '#B4F3D6', paddingSmall: '0.67rem'}}
          padding="small"
          width="3.3rem"
          height="3.3rem"
          margin="small small none none"
          borderRadius="circle"
        >
          <IconClockLine color="alert" size="small" themeOverride={{alertColor: '#068447'}} />
        </View>
        <View
          data-testid="course-pace-duration"
          display="inline-block"
          margin="small none none none"
        >
          {getColoredText('#30203A', I18n.t('Time to complete'))}
          {getColoredText('#068447', duration, {as: 'div', weight: 'bold'})}
        </View>
      </View>
    )
  }

  return (
    <Flex
      data-testid="projected-dates-redesign"
      direction={shrink ? 'column' : 'row'}
      margin="none none small none"
      alignItems="stretch"
    >
      {hasAtLeastOneDate() && <Flex.Item>{renderDates()}</Flex.Item>}
      <Flex.Item>{renderAssignmentsSection()}</Flex.Item>
      <Flex.Item>{renderDurationSection()}</Flex.Item>
    </Flex>
  )
}

export default PaceModalStats

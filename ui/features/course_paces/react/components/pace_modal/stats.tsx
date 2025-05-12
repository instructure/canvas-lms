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

import React, {type ReactNode, useEffect, useState} from 'react'
import moment from 'moment-timezone'
import {useScope as createI18nScope} from '@canvas/i18n'
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
import type {CoursePace, OptionalDate, Pace, PaceDuration, ResponsiveSizes} from '../../types'
import {coursePaceActions} from '../../actions/course_paces'
import {generateDatesCaptions, getEndDateValue} from '../../utils/date_stuff/date_helpers'

const I18n = createI18nScope('course_paces_projected_dates')

const DASH = String.fromCharCode(0x2013)

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
  const startDateValue = coursePace.start_date
  const endDateValue = getEndDateValue(coursePace, plannedEndDate)

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

  // @ts-expect-error
  const renderColoredDate = (label, dateValue, helpText, testid) => {
    return (
      <View data-testid={testid} display="inline-block">
        <View as="div" margin="0">
          {getColoredText('#30203A', label)}
        </View>
        <View data-testid="coursepace-date-text" as="div" margin="xxx-small 0 0 0">
          {dateValue
            ? getColoredText(
                '#5C1C78',
                dateFormatter(moment.tz(dateValue, coursePaceTimezone).toDate()),
                {weight: 'bold'},
              )
            : getColoredText('#5C1C78', `${DASH} ${I18n.t('Not Specified')} ${DASH}`, {
                weight: 'bold',
              })}
        </View>
        {!shrink && (
          <div>
            {getColoredText('#5C1C78', <span>{helpText}</span>, {
              fontStyle: 'italic',
              size: 'small',
            })}
          </div>
        )}
      </View>
    )
  }

  const renderDates = (shrink: boolean) => {
    const captions = generateDatesCaptions(coursePace, startDateValue, endDateValue, appliedPace)

    if (shrink) {
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
                themeOverride={{alertColor: '#5C1C78'}}
              />
            </View>
            {renderColoredDate(
              I18n.t('Start Date'),
              startDateValue,
              captions.startDate,
              'coursepace-start-date',
            )}
          </Flex.Item>
          <Flex.Item margin="0 medium medium 0" shouldGrow={true}>
            <View margin="none small none none">
              <IconArrowEndLine
                color="alert"
                size="x-small"
                themeOverride={{alertColor: '#5C1C78'}}
              />
            </View>
            {renderColoredDate(
              I18n.t('End Date'),
              endDateValue,
              captions.endDate,
              'coursepace-end-date',
            )}
          </Flex.Item>
        </View>
      )
    } else {
      return (
        <View
          as="div"
          background="alert"
          themeOverride={{backgroundAlert: '#F9F0FF'}}
          padding="small medium"
          borderRadius="medium"
          height="100%"
        >
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
              themeOverride={{alertColor: '#5C1C78'}}
            />
          </View>
          <Flex direction="row">
            <Flex.Item margin="0 medium medium 0" shouldShrink>
              {renderColoredDate(
                I18n.t('Start Date'),
                startDateValue,
                captions.startDate,
                'coursepace-start-date',
              )}
            </Flex.Item>
            <Flex.Item margin="none small none none">
              <IconArrowEndLine
                color="alert"
                size="x-small"
                themeOverride={{alertColor: '#5C1C78'}}
              />
            </Flex.Item>
            <Flex.Item margin="0 medium medium 0" shouldGrow shouldShrink>
              {renderColoredDate(
                I18n.t('End Date'),
                endDateValue,
                captions.endDate,
                'coursepace-end-date',
              )}
            </Flex.Item>
          </Flex>
        </View>
      )
    }
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
          <IconAssignmentLine color="alert" size="small" themeOverride={{alertColor: '#2B7ABC'}} />
        </View>
        <View
          data-testid="course-pace-assignment-number"
          display="inline-block"
          margin="small none none none"
        >
          {getColoredText('#30203A', I18n.t('Assignments'))}
          {getColoredText('#2B7ABC', assignments, {as: 'div', weight: 'bold'})}
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
      {count: paceDuration.weeks},
    )
    const days = I18n.t(
      {
        one: '1 day',
        other: '%{count} days',
      },
      {count: paceDuration.days},
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
      {hasAtLeastOneDate() && <Flex.Item shouldShrink>{renderDates(shrink)}</Flex.Item>}
      <Flex.Item shouldShrink>{renderAssignmentsSection()}</Flex.Item>
      <Flex.Item shouldShrink>{renderDurationSection()}</Flex.Item>
    </Flex>
  )
}

export default PaceModalStats

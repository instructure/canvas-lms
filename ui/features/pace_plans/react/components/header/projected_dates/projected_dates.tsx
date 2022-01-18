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

import React, {useCallback, useEffect, useState} from 'react'
import {connect} from 'react-redux'
import moment from 'moment-timezone'
// @ts-ignore: TS doesn't understand i18n scoped imports
import I18n from 'i18n!pace_plans_projected_dates'

import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {PresentationContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

import {BlackoutDate, InputInteraction} from '../../../shared/types'
import {StoreState, PacePlan} from '../../../types'
import {pacePlanActions as actions} from '../../../actions/pace_plans'
import {
  getPacePlan,
  getPacePlanItems,
  getPlanWeeks,
  getProjectedEndDate,
  getExcludeWeekends,
  getPlanPublishing
} from '../../../reducers/pace_plans'
import {getBlackoutDates} from '../../../shared/reducers/blackout_dates'
import {getShowProjections} from '../../../reducers/ui'
import PacePlanDateInput, {
  PacePlansDateInputProps
} from '../../../shared/components/pace_plan_date_input'
import SlideTransition from '../../../utils/slide_transition'

interface StoreProps {
  readonly pacePlan: PacePlan
  readonly planPublishing: boolean
  readonly projectedEndDate: string
  readonly assignments: number
  readonly planWeeks: number
  readonly showProjections: boolean
  readonly weekendsDisabled: boolean
  readonly blackoutDates: BlackoutDate[]
}

type DispatchProps = {
  setStartDate: typeof actions.setStartDate
  readonly setEndDate: typeof actions.setEndDate
  compressDates: typeof actions.compressDates
  uncompressDates: typeof actions.uncompressDates
  readonly toggleHardEndDates: typeof actions.toggleHardEndDates
}

type ComponentProps = StoreProps & DispatchProps

export const ProjectedDates: React.FC<ComponentProps> = ({
  pacePlan,
  assignments,
  planPublishing,
  planWeeks,
  projectedEndDate,
  setStartDate,
  setEndDate,
  compressDates,
  uncompressDates,
  toggleHardEndDates,
  showProjections,
  blackoutDates,
  weekendsDisabled
}) => {
  const [startMessage, setStartMessage] = useState<PacePlansDateInputProps['message'] | undefined>(
    undefined
  )

  // PacePlanDateInput.validateDay plays 2 roles
  // 1. validate the new date in response to a date change
  // 2. to determine valid dates in the INSTUI DateInput's popup calendar
  // so we can only return an error message when the input date
  // is invalid and can't do any cross-field validation.
  // See useEffect for that
  const validateStart = useCallback(
    (date: moment.Moment) => {
      if (
        ENV.VALID_DATE_RANGE.start_at.date &&
        date.isBefore(moment(ENV.VALID_DATE_RANGE.start_at.date), 'day')
      ) {
        return I18n.t('Date is before the course start date')
      }

      if (pacePlan.hard_end_dates && date.isAfter(moment(pacePlan.end_date), 'day')) {
        return I18n.t('Date is after the specified end date')
      }

      if (
        !pacePlan.hard_end_dates &&
        ENV.VALID_DATE_RANGE.end_at.date &&
        date.isAfter(moment(ENV.VALID_DATE_RANGE.end_at.date), 'day')
      ) {
        return I18n.t('Date is after the course end date')
      }
    },
    [pacePlan.end_date, pacePlan.hard_end_dates]
  )

  useEffect(() => {
    // If the projected start date pushes the projected end date out of
    // bounds, we show the error message on projected start date.
    // Since we may not have a new projected end date yet when validateStart
    // is called, do it here.
    if (
      (pacePlan.hard_end_dates && pacePlan.end_date && projectedEndDate > pacePlan.end_date) ||
      moment(projectedEndDate) > moment(ENV.VALID_DATE_RANGE.end_at.date)
    ) {
      compressDates()
    } else {
      uncompressDates()
      setStartMessage(undefined)
    }
  }, [compressDates, pacePlan.end_date, pacePlan.hard_end_dates, projectedEndDate, uncompressDates])

  const enrollmentType = pacePlan.context_type === 'Enrollment'

  const startDateValue = pacePlan.start_date
  const startHelpText = enrollmentType
    ? I18n.t('Student enrollment date')
    : I18n.t('Hypothetical student enrollment date')

  let endDateValue, endHelpText, endDateInteraction
  if (pacePlan.hard_end_dates) {
    endDateValue = pacePlan.end_date
    endHelpText = I18n.t('Required by specified end date')
    endDateInteraction = planPublishing ? 'disabled' : 'enabled'
  } else if (ENV.VALID_DATE_RANGE.end_at.date) {
    endDateValue = ENV.VALID_DATE_RANGE.end_at.date
    if (ENV.VALID_DATE_RANGE.end_at.date_context === 'course') {
      endHelpText = I18n.t('Required by course end date')
    } else {
      endHelpText = I18n.t('Required by term end date')
    }
    endDateInteraction = 'readonly'
  } else {
    endDateValue = projectedEndDate
    endHelpText = I18n.t('Hypothetical end date')
    endDateInteraction = 'readonly'
  }

  let startInteraction: InputInteraction = 'enabled'
  if (enrollmentType) {
    startInteraction = 'readonly'
  } else if (planPublishing) {
    startInteraction = 'disabled'
  }

  return (
    <SlideTransition expanded={showProjections} direction="vertical" size="30rem">
      <View as="div">
        <Flex as="section" alignItems="center" margin="0" wrap="wrap">
          <Flex.Item margin="0 medium medium 0" shouldGrow>
            <PacePlanDateInput
              label={I18n.t('Start Date')}
              helpText={startHelpText}
              message={startMessage}
              interaction={startInteraction}
              dateValue={startDateValue}
              onDateChange={setStartDate}
              weekendsDisabled={weekendsDisabled}
              blackoutDates={blackoutDates}
              validateDay={validateStart}
              width="15rem"
            />
          </Flex.Item>
          <Flex.Item margin="0 medium medium 0" shouldGrow>
            <PacePlanDateInput
              id="pace-plans-required-end-date-input"
              label={I18n.t('End Date')}
              helpText={endHelpText}
              interaction={endDateInteraction}
              dateValue={endDateValue}
              onDateChange={setEndDate}
              width="15rem"
            />
          </Flex.Item>
          <Flex.Item margin="0 medium medium 0" align="center">
            <Checkbox
              data-testid="require-end-date-toggle"
              label={I18n.t('Require Completion by Specified End Date')}
              checked={pacePlan.hard_end_dates}
              disabled={planPublishing}
              onChange={() => {
                toggleHardEndDates()
              }}
            />
          </Flex.Item>
        </Flex>
        <Flex as="section" justifyItems="space-between" wrap="wrap" margin="0 0 x-small">
          <Flex.Item margin="0 x-small x-small 0">
            <View padding="0 xxx-small 0 0" margin="0 x-small 0 0">
              <Text>
                <i>
                  {I18n.t(
                    {
                      one: '1 assignment',
                      other: '%{count} assignments'
                    },
                    {count: assignments}
                  )}
                </i>
              </Text>
            </View>
            <PresentationContent>
              <Text color="secondary">|</Text>
            </PresentationContent>
            <View margin="0 0 0 x-small">
              <Text>
                <i>
                  {I18n.t(
                    {
                      one: '1 week',
                      other: '%{count} weeks'
                    },
                    {count: planWeeks}
                  )}
                </i>
              </Text>
            </View>
          </Flex.Item>
          <Flex.Item margin="0 0 x-small">
            <Text fontStyle="italic">{I18n.t('Dates shown in course time zone')}</Text>
          </Flex.Item>
        </Flex>
      </View>
    </SlideTransition>
  )
}

const mapStateToProps = (state: StoreState) => {
  return {
    pacePlan: getPacePlan(state),
    assignments: getPacePlanItems(state).length,
    planWeeks: getPlanWeeks(state),
    showProjections: getShowProjections(state),
    projectedEndDate: getProjectedEndDate(state),
    weekendsDisabled: getExcludeWeekends(state),
    blackoutDates: getBlackoutDates(state),
    planPublishing: getPlanPublishing(state)
  }
}

export default connect(mapStateToProps, {
  setStartDate: actions.setStartDate,
  setEndDate: actions.setEndDate,
  compressDates: actions.compressDates,
  uncompressDates: actions.uncompressDates,
  toggleHardEndDates: actions.toggleHardEndDates
})(ProjectedDates)

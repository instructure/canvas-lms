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

import React, {useCallback} from 'react'
import {connect} from 'react-redux'
// @ts-ignore: TS doesn't understand i18n scoped imports
import I18n from 'i18n!pace_plan_date_selector'
import moment from 'moment-timezone'

import PacePlanDateInput from '../../../shared/components/pace_plan_date_input'
import {StoreState, PacePlan} from '../../../types'
import {BlackoutDate, InputInteraction} from '../../../shared/types'
import {
  getPacePlan,
  getPlanPublishing,
  getProjectedEndDate,
  getStartDate,
  getExcludeWeekends
} from '../../../reducers/pace_plans'
import {getBlackoutDates} from '../../../shared/reducers/blackout_dates'
import {pacePlanActions as actions} from '../../../actions/pace_plans'

type StoreProps = {
  pacePlan: PacePlan
  projectedEndDate?: string
  projectedStartDate?: string
  weekendsDisabled?: boolean
  blackoutDates: BlackoutDate[]
  planPublishing: boolean
}

type DispatchProps = {
  setStartDate: typeof actions.setStartDate
  setEndDate: typeof actions.setEndDate
}

type PassedProps = {
  type: 'start' | 'end' | 'end-selection'
  label?: Object
  width: string
}

export type PacePlanDateSelectorProps = StoreProps & DispatchProps & PassedProps

export const PacePlanDateSelector = (props: PacePlanDateSelectorProps) => {
  const startType = props.type === 'start'
  const endSelectionType = props.type === 'end-selection'
  const enrollmentType = props.pacePlan.context_type === 'Enrollment'

  const validateDay = useCallback(
    (date: moment.Moment) => {
      const crossesOtherDate = startType
        ? date > moment(props.pacePlan.end_date)
        : date < moment(props.projectedStartDate)

      const errors: string[] = []
      if (crossesOtherDate)
        errors.push(
          startType
            ? I18n.t('The start date for the pace plan must be before the end date.')
            : I18n.t('The end date for the pace plan must be after the start date.')
        )

      return errors.join(' ')
    },
    [startType, props.pacePlan.end_date, props.projectedStartDate]
  )

  let interaction: InputInteraction = 'enabled'
  if (enrollmentType || !(startType || endSelectionType)) {
    interaction = 'readonly'
  } else if (props.planPublishing) {
    interaction = 'disabled'
  }

  let label
  if (props.label) {
    label = props.label
  } else {
    label = startType
      ? enrollmentType
        ? I18n.t('Start Date')
        : I18n.t('Projected Start Date')
      : enrollmentType
      ? I18n.t('End Date')
      : I18n.t('Projected End Date')
  }

  let dateValue
  if (startType) {
    dateValue = props.pacePlan.start_date
  } else if (props.type === 'end-selection') {
    dateValue = props.pacePlan.end_date
  } else {
    dateValue = props.projectedEndDate
  }

  return (
    <PacePlanDateInput
      interaction={interaction}
      dateValue={dateValue}
      onDateChange={startType ? props.setStartDate : props.setEndDate}
      validateDay={validateDay}
      label={label}
      width={props.width || '14rem'}
      blackoutDates={props.blackoutDates}
      weekendsDisabled={props.weekendsDisabled}
    />
  )
}

const mapStateToProps = (state: StoreState) => {
  return {
    pacePlan: getPacePlan(state),
    weekendsDisabled: getExcludeWeekends(state),
    blackoutDates: getBlackoutDates(state),
    projectedEndDate: getProjectedEndDate(state),
    projectedStartDate: getStartDate(state),
    planPublishing: getPlanPublishing(state)
  }
}

export default connect(mapStateToProps, {
  setStartDate: actions.setStartDate,
  setEndDate: actions.setEndDate
})(PacePlanDateSelector)

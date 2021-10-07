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

import React from 'react'
import {connect} from 'react-redux'
// @ts-ignore: TS doesn't understand i18n scoped imports
import I18n from 'i18n!pace_plans_start_date_selector'
import moment from 'moment-timezone'

import {autoSavingActions as actions} from '../../../actions/pace_plans'
import PacePlanDateInput from '../../../shared/components/pace_plan_date_input'
import {StoreState, PacePlan} from '../../../types'
import {BlackoutDate} from '../../../shared/types'
import {getPacePlan, getDisabledDaysOfWeek} from '../../../reducers/pace_plans'
import {getBlackoutDates} from '../../../shared/reducers/blackout_dates'
import * as DateHelpers from '../../../utils/date_stuff/date_helpers'

interface StoreProps {
  readonly blackoutDates: BlackoutDate[]
  readonly disabledDaysOfWeek: number[]
  readonly pacePlan: PacePlan
}

interface DispatchProps {
  readonly setStartDate: typeof actions.setStartDate
}

type ComponentProps = StoreProps & DispatchProps

export class StartDateSelector extends React.Component<ComponentProps> {
  onDateChange = (rawValue: string) => {
    this.props.setStartDate(rawValue)
  }

  isDayDisabled = (date: moment.Moment) => {
    return (
      date > moment(this.props.pacePlan.end_date) ||
      DateHelpers.inBlackoutDate(date, this.props.blackoutDates)
    )
  }

  render() {
    return (
      <PacePlanDateInput
        id="start-date"
        dateValue={this.props.pacePlan.start_date}
        disabledDaysOfWeek={this.props.disabledDaysOfWeek}
        disabledDays={this.isDayDisabled}
        interaction={this.props.pacePlan.context_type === 'Enrollment' ? 'readonly' : 'enabled'}
        label={
          this.props.pacePlan.context_type === 'Enrollment'
            ? I18n.t('Start Date')
            : I18n.t('Projected Start Date')
        }
        onDateChange={this.onDateChange}
        width="14rem"
      />
    )
  }
}

const mapStateToProps = (state: StoreState): StoreProps => {
  return {
    blackoutDates: getBlackoutDates(state),
    disabledDaysOfWeek: getDisabledDaysOfWeek(state),
    pacePlan: getPacePlan(state)
  }
}

export default connect(mapStateToProps, {setStartDate: actions.setStartDate} as DispatchProps)(
  StartDateSelector
)

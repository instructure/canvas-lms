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
import {NumberInput} from '@instructure/ui-number-input'

import {StoreState, PacePlan} from '../../../types'
import {BlackoutDate} from '../../../shared/types'
import {
  getPlanDays,
  getPlanWeeks,
  getPacePlan,
  getWeekLength,
  isPlanCompleted
} from '../../../reducers/pace_plans'
import {autoSavingActions as actions} from '../../../actions/pace_plans'
import {getDivideIntoWeeks, getEditingBlackoutDates} from '../../../reducers/ui'
import {getBlackoutDates} from '../../../shared/reducers/blackout_dates'

interface StoreProps {
  readonly planDays: number
  readonly planWeeks: number
  readonly divideIntoWeeks: boolean
  readonly pacePlan: PacePlan
  readonly weekLength: number
  readonly blackoutDates: BlackoutDate[]
  readonly editingBlackoutDates: boolean
  readonly planCompleted: boolean
}

interface DispatchProps {
  readonly setPlanDays: typeof actions.setPlanDays
}

type ComponentProps = StoreProps & DispatchProps

interface LocalState {
  readonly planWeeks: number | string
}

// This component has to keep a local and Redux version of planDays.
// The local version is needed so that we don't commit to redux (and recalculate)
// until there's a valid value. The DaysSelector and AssignmentRow components
// are following a similar pattern and could maybe be refactored to use the same
// component wrapping around NumberInput.
export class WeeksSelector extends React.Component<ComponentProps, LocalState> {
  /* Lifecycle */

  constructor(props: ComponentProps) {
    super(props)
    this.state = {planWeeks: props.planWeeks}
    this.commitChanges = this.commitChanges.bind(this)
  }

  // If blackout dates are being edited, we don't want to try and re-calculate the weeks
  // until they've all been saved to the backend, and the plan has been re-loaded.
  shouldComponentUpdate(nextProps: ComponentProps) {
    return !nextProps.editingBlackoutDates
  }

  /* Callbacks */

  commitChanges = () => {
    const weeks =
      typeof this.state.planWeeks === 'string'
        ? parseInt(this.state.planWeeks, 10)
        : this.state.planWeeks

    if (!Number.isNaN(weeks)) {
      const totalNumberOfDays =
        weeks * this.props.weekLength + (this.props.planDays % this.props.weekLength)
      if (totalNumberOfDays !== this.props.planDays) {
        this.props.setPlanDays(totalNumberOfDays, this.props.pacePlan, this.props.blackoutDates)
      }
    }
  }

  onChangeNumWeeks = (_e: React.FormEvent<HTMLInputElement>, weeks: string | number) => {
    weeks = typeof weeks !== 'number' ? parseInt(weeks, 10) : weeks
    if (weeks < 0) return // don't allow negative weeks
    const weeksFormatted = Number.isNaN(weeks) ? '' : weeks
    this.setState({planWeeks: weeksFormatted}, this.commitChanges)
  }

  onDecrementOrIncrement = (e: React.FormEvent<HTMLInputElement>, direction: number) => {
    const currentWeeks =
      typeof this.state.planWeeks === 'string'
        ? parseInt(this.state.planWeeks, 10)
        : this.state.planWeeks
    this.onChangeNumWeeks(e, currentWeeks + direction)
  }

  /* Helpers */

  disabled() {
    return (
      this.props.planCompleted ||
      !this.props.divideIntoWeeks ||
      (this.props.pacePlan.context_type === 'Enrollment' && this.props.pacePlan.hard_end_dates)
    )
  }

  /* Renderers */

  render() {
    const weeks = this.props.divideIntoWeeks ? this.state.planWeeks : ''

    return (
      <NumberInput
        renderLabel="Weeks"
        width="90px"
        value={weeks.toString()}
        onDecrement={e => this.onDecrementOrIncrement(e, -1)}
        onIncrement={e => this.onDecrementOrIncrement(e, 1)}
        onChange={this.onChangeNumWeeks}
        interaction={this.disabled() ? 'disabled' : 'enabled'}
      />
    )
  }
}

const mapStateToProps = (state: StoreState): StoreProps => {
  const planWeeks = getPlanWeeks(state)
  return {
    planDays: getPlanDays(state),
    planWeeks,
    divideIntoWeeks: getDivideIntoWeeks(state),
    pacePlan: getPacePlan(state),
    weekLength: getWeekLength(state),
    blackoutDates: getBlackoutDates(state),
    editingBlackoutDates: getEditingBlackoutDates(state),
    planCompleted: isPlanCompleted(state),
    // Used to reset the selector to weeks coming from the Redux store when they change there
    key: `weeks-selector-${planWeeks}`
  }
}

export default connect(mapStateToProps, {setPlanDays: actions.setPlanDays} as DispatchProps)(
  WeeksSelector
)

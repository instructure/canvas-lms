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
import {getDivideIntoWeeks, getEditingBlackoutDates} from '../../../reducers/ui'
import {autoSavingActions as actions} from '../../../actions/pace_plans'
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

type ConnectedComponentProps = StoreProps & {
  readonly key: string
}

type ComponentProps = StoreProps & DispatchProps

interface LocalState {
  readonly planDays: number | string
}

// This component has to keep a local and Redux version of planDays.
// The local version is needed so that we don't commit to redux (and recalculate)
// until there's a valid value. The WeeksSelector and AssignmentRow components
// are following a similar pattern and could maybe be *REFACTOR*ed to use the same
// component wrapping around NumberInput.
export class DaysSelector extends React.Component<ComponentProps, LocalState> {
  /* Lifecycle */

  constructor(props: ComponentProps) {
    super(props)
    this.state = {planDays: props.planDays}
  }

  // If blackout dates are being edited, we don't want to try and re-calculate the days
  // until they've all been saved to the backend, and the plan has been re-loaded.
  shouldComponentUpdate(nextProps: ComponentProps) {
    return !nextProps.editingBlackoutDates
  }

  /* Callbacks */

  commitChanges = () => {
    const days =
      typeof this.state.planDays === 'string'
        ? parseInt(this.state.planDays, 10)
        : this.state.planDays

    if (!Number.isNaN(days) && days !== this.props.planDays) {
      this.props.setPlanDays(days, this.props.pacePlan, this.props.blackoutDates)
    }
  }

  onChangeNumDays = (_e: React.FormEvent<HTMLInputElement>, days: string | number) => {
    let daysFormatted: number | string
    const daysAsInt = typeof days === 'string' ? parseInt(days, 10) : days

    if (Number.isNaN(daysAsInt)) {
      daysFormatted = ''
    } else if (daysAsInt < 0 || (daysAsInt > this.props.weekLength && this.props.divideIntoWeeks)) {
      return
    } else {
      daysFormatted = this.props.divideIntoWeeks
        ? this.props.planWeeks * this.props.weekLength + daysAsInt
        : daysAsInt
    }

    this.setState({planDays: daysFormatted}, this.commitChanges)
  }

  onDecrementOrIncrement = (e: React.FormEvent<HTMLInputElement>, direction: number) => {
    let days = this.displayDays()
    days = typeof days === 'string' ? parseInt(days, 10) : days
    this.onChangeNumDays(e, days + direction)
  }

  /* Helpers */

  disabled() {
    return (
      this.props.planCompleted ||
      (this.props.pacePlan.context_type === 'Enrollment' && this.props.pacePlan.hard_end_dates)
    )
  }

  displayDays() {
    if (!this.props.divideIntoWeeks || typeof this.state.planDays === 'string') {
      return this.state.planDays
    } else {
      return this.state.planDays % this.props.weekLength
    }
  }

  /* Renderers */

  render() {
    return (
      <NumberInput
        renderLabel="Days"
        width="90px"
        value={this.displayDays().toString()}
        onDecrement={e => this.onDecrementOrIncrement(e, -1)}
        onIncrement={e => this.onDecrementOrIncrement(e, 1)}
        onChange={this.onChangeNumDays}
        interaction={this.disabled() ? 'disabled' : 'enabled'}
      />
    )
  }
}

const mapStateToProps = (state: StoreState): ConnectedComponentProps => {
  const planDays = getPlanDays(state)
  return {
    planDays,
    planWeeks: getPlanWeeks(state),
    divideIntoWeeks: getDivideIntoWeeks(state),
    pacePlan: getPacePlan(state),
    weekLength: getWeekLength(state),
    blackoutDates: getBlackoutDates(state),
    editingBlackoutDates: getEditingBlackoutDates(state),
    planCompleted: isPlanCompleted(state),
    // Used to reset the selector to days coming from the Redux store when they change there
    key: `days-selector-${planDays}`
  }
}

export default connect(mapStateToProps, {setPlanDays: actions.setPlanDays} as DispatchProps)(
  DaysSelector
)

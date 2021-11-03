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
import I18n from 'i18n!pace_plans_assignment_row'
import {debounce, pick} from 'lodash'
import moment from 'moment-timezone'

import {ApplyTheme} from '@instructure/ui-themeable'
import {Flex} from '@instructure/ui-flex'
import {
  IconAssignmentLine,
  IconDiscussionLine,
  IconPublishSolid,
  IconQuizLine,
  IconUnpublishedLine
} from '@instructure/ui-icons'
import {NumberInput} from '@instructure/ui-number-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Table} from '@instructure/ui-table'
import {Text} from '@instructure/ui-text'
import {TruncateText} from '@instructure/ui-truncate-text'
import {View} from '@instructure/ui-view'

import {PacePlanItem, PacePlan, StoreState} from '../../types'
import {BlackoutDate} from '../../shared/types'
import {
  getPacePlan,
  getDueDate,
  getExcludeWeekends,
  getPacePlanItemPosition
} from '../../reducers/pace_plans'
import {actions} from '../../actions/pace_plan_items'
import {actions as uiActions} from '../../actions/ui'
import * as DateHelpers from '../../utils/date_stuff/date_helpers'
import {
  getAutoSaving,
  getAdjustingHardEndDatesAfter,
  getPlanPublishing,
  getShowProjections
} from '../../reducers/ui'
import {getBlackoutDates} from '../../shared/reducers/blackout_dates'

// Doing this to avoid TS2339 errors-- remove once we're on InstUI 8
const {Cell, Row} = Table as any

interface PassedProps {
  readonly datesVisible: boolean
  readonly headers?: object[]
  readonly hover: boolean
  readonly isStacked: boolean
  readonly pacePlanItem: PacePlanItem
}

interface StoreProps {
  readonly pacePlan: PacePlan
  readonly dueDate: string
  readonly excludeWeekends: boolean
  readonly pacePlanItemPosition: number
  readonly blackoutDates: BlackoutDate[]
  readonly autosaving: boolean
  readonly enrollmentHardEndDatePlan: boolean
  readonly adjustingHardEndDatesAfter?: number
  readonly planPublishing: boolean
  readonly showProjections: boolean
}

interface DispatchProps {
  readonly setPlanItemDuration: typeof actions.setPlanItemDuration
  readonly setAdjustingHardEndDatesAfter: typeof uiActions.setAdjustingHardEndDatesAfter
}

interface LocalState {
  readonly duration: string
  readonly hovering: boolean
}

type ComponentProps = PassedProps & StoreProps & DispatchProps

export class AssignmentRow extends React.Component<ComponentProps, LocalState> {
  state: LocalState = {
    duration: String(this.props.pacePlanItem.duration),
    hovering: false
  }

  private debouncedCommitChanges: any

  /* Component lifecycle */

  constructor(props: ComponentProps) {
    super(props)
    this.debouncedCommitChanges = debounce(this.commitChanges, 300, {
      leading: false,
      trailing: true
    })
  }

  shouldComponentUpdate(nextProps: ComponentProps, nextState: LocalState) {
    return (
      nextProps.dueDate !== this.props.dueDate ||
      nextProps.adjustingHardEndDatesAfter !== this.props.adjustingHardEndDatesAfter ||
      nextState.duration !== this.state.duration ||
      nextState.hovering !== this.state.hovering ||
      nextProps.pacePlan.exclude_weekends !== this.props.pacePlan.exclude_weekends ||
      nextProps.pacePlan.context_type !== this.props.pacePlan.context_type ||
      (nextProps.pacePlan.context_type === this.props.pacePlan.context_type &&
        nextProps.pacePlan.context_id !== this.props.pacePlan.context_id) ||
      nextProps.planPublishing !== this.props.planPublishing ||
      nextProps.showProjections !== this.props.showProjections ||
      nextProps.datesVisible !== this.props.datesVisible
    )
  }

  /* Helpers */

  newDuration = (newDueDate: string | moment.Moment) => {
    const daysDiff = DateHelpers.daysBetween(
      this.props.dueDate,
      newDueDate,
      this.props.excludeWeekends,
      this.props.blackoutDates,
      false
    )
    return parseInt(this.state.duration, 10) + daysDiff
  }

  parsePositiveNumber = (value?: string): number | false => {
    if (typeof value !== 'string') return false
    try {
      const parsedInt = parseInt(value, 10)
      if (parsedInt >= 0) return parsedInt
    } catch (err) {
      return false
    }
    return false
  }

  /* Callbacks */

  onChangeItemDuration = (_e: React.FormEvent<HTMLInputElement>, value: string) => {
    if (value === '') {
      this.setState({duration: ''})
      return
    }
    const duration = this.parsePositiveNumber(value)
    if (duration !== false) {
      this.setState({duration: duration.toString()})
    }
  }

  onDecrementOrIncrement = (_e: React.FormEvent<HTMLInputElement>, direction: number) => {
    const newValue = (this.parsePositiveNumber(this.state.duration) || 0) + direction
    if (newValue < 0) return
    this.setState({duration: newValue.toString()})
    this.debouncedCommitChanges()
  }

  onBlur = (e: React.FormEvent<HTMLInputElement>) => {
    const value = (e.currentTarget?.value || '') === '' ? '0' : e.currentTarget.value
    const duration = this.parsePositiveNumber(value)
    if (duration !== false) {
      this.setState({duration: duration.toString()}, () => {
        this.commitChanges()
      })
    }
  }

  onDateChange = (isoValue: string) => {
    // Get rid of the timezone because we're only dealing with exact days and not timezones currently
    const newDuration = this.newDuration(DateHelpers.stripTimezone(isoValue))

    // If the date hasn't changed, we should force an update, which will reset the DateInput if they
    // user entered invalid data.
    const shouldForceUpdate = String(newDuration) === this.state.duration

    this.setState({duration: newDuration.toString()}, () => {
      this.commitChanges()
      if (shouldForceUpdate) {
        this.forceUpdate()
      }
    })
  }

  // Values are stored in local state while editing, and is then debounced
  // to commit the change to redux.
  commitChanges = () => {
    const duration = parseInt(this.state.duration, 10)

    if (!Number.isNaN(duration)) {
      this.props.setPlanItemDuration(this.props.pacePlanItem.module_item_id, duration)
    }
  }

  isDayDisabled = (date: moment.Moment): boolean => {
    return (
      this.newDuration(date) < 0 ||
      DateHelpers.inBlackoutDate(date, this.props.blackoutDates) ||
      (this.props.enrollmentHardEndDatePlan && date > moment(this.props.pacePlan.end_date))
    )
  }

  /* Renderers */

  renderAssignmentIcon = () => {
    const size = '20px'
    const color = this.props.pacePlanItem.published ? '#4AA937' : '#75808B'

    switch (this.props.pacePlanItem.module_item_type) {
      case 'Assignment':
        return <IconAssignmentLine width={size} height={size} style={{color}} />
      case 'Quizzes::Quiz':
        return <IconQuizLine width={size} height={size} style={{color}} />
      case 'Quiz':
        return <IconQuizLine width={size} height={size} style={{color}} />
      case 'DiscussionTopic':
        return <IconDiscussionLine width={size} height={size} style={{color}} />
      case 'Discussion':
        return <IconDiscussionLine width={size} height={size} style={{color}} />
      default:
        return <IconAssignmentLine width={size} height={size} style={{color}} />
    }
  }

  renderPublishStatusBadge = () => {
    return this.props.pacePlanItem.published ? (
      <IconPublishSolid color="success" size="x-small" title={I18n.t('Published')} />
    ) : (
      <IconUnpublishedLine size="x-small" title={I18n.t('Unpublished')} />
    )
  }

  renderDurationInput = () => {
    if (this.props.enrollmentHardEndDatePlan) {
      return null
    } else {
      const value = this.state.duration

      return (
        <NumberInput
          interaction={this.props.planPublishing ? 'disabled' : 'enabled'}
          renderLabel={
            <ScreenReaderContent>
              Duration for module {this.props.pacePlanItem.assignment_title}
            </ScreenReaderContent>
          }
          data-testid="duration-number-input"
          display="inline-block"
          width="5.5rem"
          value={value}
          onChange={this.onChangeItemDuration}
          onBlur={this.onBlur}
          onDecrement={e => this.onDecrementOrIncrement(e, -1)}
          onIncrement={e => this.onDecrementOrIncrement(e, 1)}
        />
      )
    }
  }

  renderDate = () => {
    const dateText =
      this.props.adjustingHardEndDatesAfter !== undefined &&
      this.props.pacePlanItemPosition > this.props.adjustingHardEndDatesAfter
        ? I18n.t('Adjusting due dates...')
        : moment(this.props.dueDate).format('l')
    return <Text>{dateText}</Text>
  }

  renderTitle() {
    return (
      <Flex alignItems="center">
        <View margin="0 x-small 0 0">{this.renderAssignmentIcon()}</View>
        <Text weight="bold">
          <TruncateText>{this.props.pacePlanItem.assignment_title}</TruncateText>
        </Text>
      </Flex>
    )
  }

  render() {
    const labelMargin = this.props.isStacked ? '0 0 0 small' : undefined
    const themeOverrides = {background: this.state.hovering ? '#eef7ff' : '#fff'}

    return (
      <ApplyTheme theme={{[(Cell as any).theme]: themeOverrides}}>
        <Row
          data-testid='pp-module-item-row'
          onMouseEnter={() => this.setState({hovering: true})}
          onMouseLeave={() => this.setState({hovering: false})}
          {...pick(this.props, ['hover', 'isStacked', 'headers'])}
        >
          <Cell data-testid='pp-title-cell' >
            <View margin={labelMargin}>{this.renderTitle()}</View>
          </Cell>
          <Cell>
            <View data-testid="duration-input" margin={labelMargin}>{this.renderDurationInput()}</View>
          </Cell>
          {(this.props.showProjections || this.props.datesVisible) && (
            <Cell>
              <View margin={labelMargin}>{this.renderDate()}</View>
            </Cell>
          )}
          <Cell textAlign={this.props.isStacked ? 'start' : 'center'}>
            <View margin={labelMargin}>{this.renderPublishStatusBadge()}</View>
          </Cell>
        </Row>
      </ApplyTheme>
    )
  }
}

const mapStateToProps = (state: StoreState, props: PassedProps): StoreProps => {
  const pacePlan = getPacePlan(state)

  return {
    pacePlan,
    dueDate: getDueDate(state, props),
    excludeWeekends: getExcludeWeekends(state),
    pacePlanItemPosition: getPacePlanItemPosition(state, props),
    blackoutDates: getBlackoutDates(state),
    autosaving: getAutoSaving(state),
    enrollmentHardEndDatePlan: !!(
      pacePlan.hard_end_dates && pacePlan.context_type === 'Enrollment'
    ),
    adjustingHardEndDatesAfter: getAdjustingHardEndDatesAfter(state),
    planPublishing: getPlanPublishing(state),
    showProjections: getShowProjections(state)
  }
}

const ConnectedAssignmentRow = connect(mapStateToProps, {
  setPlanItemDuration: actions.setPlanItemDuration,
  setAdjustingHardEndDatesAfter: uiActions.setAdjustingHardEndDatesAfter
})(AssignmentRow)

// This hack allows AssignmentRow to be rendered inside an InstUI Table.Body
ConnectedAssignmentRow.displayName = 'Row'

export default ConnectedAssignmentRow

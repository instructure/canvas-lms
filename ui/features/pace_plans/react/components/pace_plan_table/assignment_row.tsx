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
import {debounce} from 'lodash'
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
import {Text} from '@instructure/ui-text'
import {TruncateText} from '@instructure/ui-truncate-text'
import {View} from '@instructure/ui-view'
import moment from 'moment-timezone'

import {PacePlanItem, PacePlan, StoreState, Enrollment, Section} from '../../types'
import {BlackoutDate, Course} from '../../shared/types'
import {
  getPacePlan,
  getDueDate,
  getExcludeWeekends,
  getPacePlanItems,
  getPacePlanItemPosition,
  isPlanCompleted,
  getActivePlanContext,
  getDisabledDaysOfWeek
} from '../../reducers/pace_plans'
import {autoSavingActions as actions} from '../../actions/pace_plan_items'
import {actions as uiActions} from '../../actions/ui'
import PacePlanDateInput from '../../shared/components/pace_plan_date_input'
import * as DateHelpers from '../../utils/date_stuff/date_helpers'
import {getAutoSaving, getAdjustingHardEndDatesAfter} from '../../reducers/ui'
import {getBlackoutDates} from '../../shared/reducers/blackout_dates'

interface PassedProps {
  readonly pacePlanItem: PacePlanItem
}

interface StoreProps {
  readonly pacePlan: PacePlan
  readonly dueDate: string
  readonly excludeWeekends: boolean
  readonly pacePlanItems: PacePlanItem[]
  readonly pacePlanItemPosition: number
  readonly blackoutDates: BlackoutDate[]
  readonly planCompleted: boolean
  readonly autosaving: boolean
  readonly enrollmentHardEndDatePlan: boolean
  readonly adjustingHardEndDatesAfter?: number
  readonly activePlanContext: Course | Enrollment | Section
  readonly disabledDaysOfWeek: number[]
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

export const ColumnWrapper = ({children, center = false, ...props}) => {
  const alignment = center ? 'center' : 'start'
  return (
    <Flex alignItems={alignment} justifyItems={alignment} margin="0 small" {...props}>
      {children}
    </Flex>
  )
}

export const COLUMN_WIDTHS = {
  DURATION: 90,
  DATE: 150,
  STATUS: 45
}

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
        nextProps.pacePlan.context_id !== this.props.pacePlan.context_id)
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

  dateInputIsDisabled = (): boolean => {
    return (
      this.props.planCompleted ||
      (this.props.enrollmentHardEndDatePlan && !!this.props.adjustingHardEndDatesAfter)
    )
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
      let saveParams = {}

      // If this is a student Hard End Date plan then we should recompress
      // all items AFTER the modified item, so that we still hit the specified
      // end date.
      if (this.props.enrollmentHardEndDatePlan && duration !== this.props.pacePlanItem.duration) {
        saveParams = {compress_items_after: this.props.pacePlanItemPosition}
        this.props.setAdjustingHardEndDatesAfter(this.props.pacePlanItemPosition)
      }

      this.props.setPlanItemDuration(this.props.pacePlanItem.id, duration, saveParams)
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
      <IconPublishSolid color="success" size="x-small" />
    ) : (
      <IconUnpublishedLine size="x-small" />
    )
  }

  renderDurationInput = () => {
    if (this.props.enrollmentHardEndDatePlan) {
      return null
    } else {
      const value = this.state.duration

      return (
        <ColumnWrapper center>
          <NumberInput
            interaction={this.props.planCompleted ? 'disabled' : 'enabled'}
            renderLabel={
              <ScreenReaderContent>
                Duration for module {this.props.pacePlanItem.assignment_title}
              </ScreenReaderContent>
            }
            display="inline-block"
            width={`${COLUMN_WIDTHS.DURATION}px`}
            value={value}
            onChange={this.onChangeItemDuration}
            onBlur={this.onBlur}
            onDecrement={e => this.onDecrementOrIncrement(e, -1)}
            onIncrement={e => this.onDecrementOrIncrement(e, 1)}
          />
        </ColumnWrapper>
      )
    }
  }

  renderDateInput = () => {
    if (
      this.props.adjustingHardEndDatesAfter !== undefined &&
      this.props.pacePlanItemPosition > this.props.adjustingHardEndDatesAfter
    ) {
      return <View width={`${COLUMN_WIDTHS.DATE}px`}>Adjusting due date...</View>
    } else {
      return (
        <PacePlanDateInput
          id={String(this.props.pacePlanItem.id)}
          disabled={this.dateInputIsDisabled()}
          dateValue={this.props.dueDate}
          onDateChange={this.onDateChange}
          disabledDaysOfWeek={this.props.disabledDaysOfWeek}
          disabledDays={this.isDayDisabled}
          width={`${COLUMN_WIDTHS.DATE}px`}
          label={
            <ScreenReaderContent>
              Due Date for module {this.props.pacePlanItem.assignment_title}
            </ScreenReaderContent>
          }
        />
      )
    }
  }

  renderBody() {
    return (
      <Flex height="100%" width="100%" alignItems="center" justifyItems="space-between">
        <Flex alignItems="center" justifyItems="center">
          <View margin="0 x-small 0 0">{this.renderAssignmentIcon()}</View>
          <Text weight="bold">
            <TruncateText>{this.props.pacePlanItem.assignment_title}</TruncateText>
          </Text>
        </Flex>

        <Flex alignItems="center" justifyItems="space-between">
          {this.renderDurationInput()}
          <ColumnWrapper center>{this.renderDateInput()}</ColumnWrapper>
          <ColumnWrapper center width={`${COLUMN_WIDTHS.STATUS}px`}>
            {this.renderPublishStatusBadge()}
          </ColumnWrapper>
        </Flex>
      </Flex>
    )
  }

  render() {
    const hoverProps = this.state.hovering
      ? {
          background: 'secondary',
          borderColor: 'brand',
          borderWidth: '0 0 0 large',
          padding: 'x-small small'
        }
      : {padding: 'x-small small x-small medium'}
    return (
      <View
        as="div"
        borderWidth="0 small small"
        borderRadius="none"
        onMouseEnter={() => this.setState({hovering: true})}
        onMouseLeave={() => this.setState({hovering: false})}
      >
        <View
          as="div"
          {...hoverProps}
          theme={{
            backgroundSecondary: '#eef7ff',
            paddingMedium: '1rem'
          }}
        >
          {this.renderBody()}
        </View>
      </View>
    )
  }
}

const mapStateToProps = (state: StoreState, props: PassedProps): StoreProps => {
  const pacePlan = getPacePlan(state)

  return {
    pacePlan,
    dueDate: getDueDate(state, props),
    excludeWeekends: getExcludeWeekends(state),
    pacePlanItems: getPacePlanItems(state),
    pacePlanItemPosition: getPacePlanItemPosition(state, props),
    blackoutDates: getBlackoutDates(state),
    planCompleted: isPlanCompleted(state),
    autosaving: getAutoSaving(state),
    enrollmentHardEndDatePlan: !!(
      pacePlan.hard_end_dates && pacePlan.context_type === 'Enrollment'
    ),
    adjustingHardEndDatesAfter: getAdjustingHardEndDatesAfter(state),
    activePlanContext: getActivePlanContext(state),
    disabledDaysOfWeek: getDisabledDaysOfWeek(state)
  }
}

export default connect(mapStateToProps, {
  setPlanItemDuration: actions.setPlanItemDuration,
  setAdjustingHardEndDatesAfter: uiActions.setAdjustingHardEndDatesAfter
})(AssignmentRow)

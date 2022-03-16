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
import {useScope as useI18nScope} from '@canvas/i18n'
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

import {coursePaceTimezone} from '../../shared/api/backend_serializer'
import {CoursePaceItem, CoursePace, StoreState} from '../../types'
import {BlackoutDate} from '../../shared/types'
import {
  getCoursePace,
  getDueDate,
  getExcludeWeekends,
  getCoursePaceItemPosition,
  getPacePublishing,
  isStudentPace
} from '../../reducers/course_paces'
import {actions} from '../../actions/course_pace_items'
import * as DateHelpers from '../../utils/date_stuff/date_helpers'
import {getShowProjections} from '../../reducers/ui'
import {getBlackoutDates} from '../../shared/reducers/blackout_dates'

const I18n = useI18nScope('course_paces_assignment_row')

// Doing this to avoid TS2339 errors-- remove once we're on InstUI 8
const {Cell, Row} = Table as any

interface PassedProps {
  readonly datesVisible: boolean
  readonly headers?: object[]
  readonly hover: boolean
  readonly isStacked: boolean
  readonly coursePaceItem: CoursePaceItem
}

interface StoreProps {
  readonly coursePace: CoursePace
  readonly dueDate: string
  readonly excludeWeekends: boolean
  readonly coursePaceItemPosition: number
  readonly blackoutDates: BlackoutDate[]
  readonly pacePublishing: boolean
  readonly showProjections: boolean
  readonly isStudentPace: boolean
}

interface DispatchProps {
  readonly setPaceItemDuration: typeof actions.setPaceItemDuration
}

interface LocalState {
  readonly duration: string
  readonly hovering: boolean
}

type ComponentProps = PassedProps & StoreProps & DispatchProps

export class AssignmentRow extends React.Component<ComponentProps, LocalState> {
  state: LocalState = {
    duration: String(this.props.coursePaceItem.duration),
    hovering: false
  }

  private debouncedCommitChanges: any

  private dateFormatter: Intl.DateTimeFormat

  /* Component lifecycle */

  constructor(props: ComponentProps) {
    super(props)
    this.debouncedCommitChanges = debounce(this.commitChanges, 300, {
      leading: false,
      trailing: true
    })
    this.dateFormatter = new Intl.DateTimeFormat(ENV.LOCALE, {
      weekday: 'short',
      month: 'short',
      day: 'numeric',
      year: 'numeric',
      timeZone: coursePaceTimezone
    })
  }

  shouldComponentUpdate(nextProps: ComponentProps, nextState: LocalState) {
    return (
      nextProps.dueDate !== this.props.dueDate ||
      nextState.duration !== this.state.duration ||
      nextState.hovering !== this.state.hovering ||
      nextProps.coursePace.exclude_weekends !== this.props.coursePace.exclude_weekends ||
      nextProps.coursePace.context_type !== this.props.coursePace.context_type ||
      (nextProps.coursePace.context_type === this.props.coursePace.context_type &&
        nextProps.coursePace.context_id !== this.props.coursePace.context_id) ||
      nextProps.pacePublishing !== this.props.pacePublishing ||
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
      this.props.setPaceItemDuration(this.props.coursePaceItem.module_item_id, duration)
    }
  }

  isDayDisabled = (date: moment.Moment): boolean => {
    return this.newDuration(date) < 0 || DateHelpers.inBlackoutDate(date, this.props.blackoutDates)
  }

  /* Renderers */

  renderAssignmentIcon = () => {
    const size = '20px'
    const color = this.props.coursePaceItem.published ? '#4AA937' : '#75808B'

    switch (this.props.coursePaceItem.module_item_type) {
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
    return this.props.coursePaceItem.published ? (
      <IconPublishSolid color="success" size="x-small" title={I18n.t('Published')} />
    ) : (
      <IconUnpublishedLine size="x-small" title={I18n.t('Unpublished')} />
    )
  }

  renderDurationInput = () => {
    if (this.props.isStudentPace) {
      return (
        <Flex height="2.375rem" alignItems="center" justifyItems="center">
          {this.state.duration}
        </Flex>
      )
    }

    return (
      <NumberInput
        interaction={this.props.pacePublishing ? 'disabled' : 'enabled'}
        renderLabel={
          <ScreenReaderContent>
            Duration for module {this.props.coursePaceItem.assignment_title}
          </ScreenReaderContent>
        }
        data-testid="duration-number-input"
        display="inline-block"
        width="5.5rem"
        value={this.state.duration}
        onChange={this.onChangeItemDuration}
        onBlur={this.onBlur}
        onDecrement={e => this.onDecrementOrIncrement(e, -1)}
        onIncrement={e => this.onDecrementOrIncrement(e, 1)}
      />
    )
  }

  renderDate = () => {
    // change the date format and you'll probably have to change
    // the column width in AssignmentRow
    return this.dateFormatter.format(new Date(this.props.dueDate))
  }

  renderTitle() {
    return (
      <Flex alignItems="center">
        <View margin="0 x-small 0 0">{this.renderAssignmentIcon()}</View>
        <div>
          <Text weight="bold">
            <a href={this.props.coursePaceItem.assignment_link} style={{color: 'inherit'}}>
              <TruncateText>{this.props.coursePaceItem.assignment_title}</TruncateText>
            </a>
          </Text>
          {typeof this.props.coursePaceItem.points_possible === 'number' && (
            <span className="course-paces-assignment-row-points-possible">
              <Text size="x-small">
                {I18n.t(
                  {one: '1 pt', other: '%{count} pts'},
                  {count: this.props.coursePaceItem.points_possible}
                )}
              </Text>
            </span>
          )}
        </div>
      </Flex>
    )
  }

  render() {
    const labelMargin = this.props.isStacked ? '0 0 0 small' : undefined
    const themeOverrides = {background: this.state.hovering ? '#eef7ff' : '#fff'}

    return (
      <ApplyTheme theme={{[(Cell as any).theme]: themeOverrides}}>
        <Row
          data-testid="pp-module-item-row"
          onMouseEnter={() => this.setState({hovering: true})}
          onMouseLeave={() => this.setState({hovering: false})}
          {...pick(this.props, ['hover', 'isStacked', 'headers'])}
        >
          <Cell data-testid="pp-title-cell">
            <View margin={labelMargin}>{this.renderTitle()}</View>
          </Cell>
          <Cell textAlign="center">
            <View data-testid="duration-input" margin={labelMargin}>
              {this.renderDurationInput()}
            </View>
          </Cell>
          {(this.props.showProjections || this.props.datesVisible) && (
            <Cell textAlign="center">
              <View data-testid="assignment-due-date" margin={labelMargin}>
                {this.renderDate()}
              </View>
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
  const coursePace = getCoursePace(state)

  return {
    coursePace,
    dueDate: getDueDate(state, props),
    excludeWeekends: getExcludeWeekends(state),
    coursePaceItemPosition: getCoursePaceItemPosition(state, props),
    blackoutDates: getBlackoutDates(state),
    pacePublishing: getPacePublishing(state),
    showProjections: getShowProjections(state),
    isStudentPace: isStudentPace(state)
  }
}

const ConnectedAssignmentRow = connect(mapStateToProps, {
  setPaceItemDuration: actions.setPaceItemDuration
})(AssignmentRow)

// This hack allows AssignmentRow to be rendered inside an InstUI Table.Body
ConnectedAssignmentRow.displayName = 'Row'

export default ConnectedAssignmentRow

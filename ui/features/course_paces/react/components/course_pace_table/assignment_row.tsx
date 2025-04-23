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

import React, {KeyboardEvent, MouseEvent} from 'react'
import {connect} from 'react-redux'
import {useScope as createI18nScope} from '@canvas/i18n'
import {debounce, pick} from 'lodash'
import moment from 'moment-timezone'

import {InstUISettingsProvider} from '@instructure/emotion'
import {FlaggableNumberInput} from './flaggable_number_input'
import {Flex} from '@instructure/ui-flex'
import {
  IconAssignmentLine,
  IconDiscussionLine,
  IconOffLine,
  IconPublishSolid,
  IconQuizLine,
  IconUnpublishedLine,
  IconWarningLine
} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Table} from '@instructure/ui-table'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {coursePaceDateFormatter} from '../../shared/api/backend_serializer'
import type {CoursePaceItem, CoursePace, StoreState, MasteryPathsData} from '../../types'
import type {BlackoutDate} from '../../shared/types'
import {
  getCoursePace,
  getExcludeWeekends,
  getCoursePaceItemPosition,
  isStudentPace,
  getCoursePaceItemChanges,
  getSelectedDaysToSkip,
} from '../../reducers/course_paces'
import {actions} from '../../actions/course_pace_items'
import { coursePaceActions } from '../../actions/course_paces'
import * as DateHelpers from '../../utils/date_stuff/date_helpers'
import {
  getShowProjections,
  getSyncing,
  getSelectedContextType,
  getBlueprintLocked,
} from '../../reducers/ui'
import {getBlackoutDates} from '../../shared/reducers/blackout_dates'
import type {Change} from '../../utils/change_tracking'
import CyoeHelper from '@canvas/conditional-release-cyoe-helper'
import {Link} from '@instructure/ui-link'
import {Pill} from '@instructure/ui-pill'
import { Tooltip } from '@instructure/ui-tooltip'

const I18n = createI18nScope('course_paces_assignment_row')

interface PassedProps {
  readonly datesVisible: boolean
  readonly headers?: object[]
  readonly hover: boolean
  readonly isStacked: boolean
  readonly coursePaceItem: CoursePaceItem
  readonly dueDate: string | moment.Moment
}

interface StoreProps {
  readonly coursePace: CoursePace
  readonly blueprintLocked: boolean | undefined
  readonly excludeWeekends: boolean
  readonly selectedDaysToSkip: string[]
  readonly coursePaceItemPosition: number
  readonly blackoutDates: BlackoutDate[]
  readonly isSyncing: boolean
  readonly showProjections: boolean
  readonly isStudentPace: boolean
  readonly context_type: string
  readonly coursePaceItemChanges: Change<CoursePaceItem>[]
}

interface DispatchProps {
  readonly setPaceItemDuration: typeof actions.setPaceItemDuration
  readonly setPaceItemDurationTimeToCompleteCalendarDays: typeof coursePaceActions.setPaceItemDurationTimeToCompleteCalendarDays
}

interface LocalState {
  readonly duration: string
  readonly hovering: boolean
}

export type ComponentProps = PassedProps & StoreProps & DispatchProps

export class AssignmentRow extends React.Component<ComponentProps, LocalState> {
  state: LocalState = {
    duration: String(this.props.coursePaceItem.duration),
    hovering: false,
  }

  private debouncedCommitChanges: any

  private dateFormatter: any

  /* Component lifecycle */

  constructor(props: ComponentProps) {
    super(props)
    this.debouncedCommitChanges = debounce(this.commitChanges, 300, {
      leading: false,
      trailing: true,
    })
    this.dateFormatter = coursePaceDateFormatter()
  }

  shouldComponentUpdate(nextProps: ComponentProps, nextState: LocalState) {
    return (
      nextProps.dueDate !== this.props.dueDate ||
      nextState.duration !== this.state.duration ||
      nextState.hovering !== this.state.hovering ||
      nextProps.coursePace.exclude_weekends !== this.props.coursePace.exclude_weekends ||
      nextProps.coursePace.selected_days_to_skip !== this.props.coursePace.selected_days_to_skip ||
      nextProps.coursePace.context_type !== this.props.coursePace.context_type ||
      (nextProps.coursePace.context_type === this.props.coursePace.context_type &&
        nextProps.coursePace.context_id !== this.props.coursePace.context_id) ||
      nextProps.isSyncing !== this.props.isSyncing ||
      nextProps.showProjections !== this.props.showProjections ||
      nextProps.datesVisible !== this.props.datesVisible ||
      nextProps.coursePaceItemChanges !== this.props.coursePaceItemChanges
    )
  }

  componentDidUpdate(prevProps: Readonly<ComponentProps>) {
    // reconcile the memoized local state duration with the redux state duration if the
    // latter changes, for example due to onResetPace
    if (prevProps.coursePaceItem.duration !== this.props.coursePaceItem.duration) {
      // we're checking that a redux state change has occurred before calling setState
      this.setState({duration: String(this.props.coursePaceItem.duration)})
    }
  }

  /* Helpers */

  newDuration = (newDueDate: string | moment.Moment) => {
    const daysDiff = DateHelpers.daysBetween(
      this.props.dueDate,
      newDueDate,
      this.props.excludeWeekends,
      this.props.selectedDaysToSkip,
      this.props.blackoutDates,
      false,
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

  onDecrementOrIncrement = (
    e: KeyboardEvent<HTMLInputElement> | MouseEvent<HTMLButtonElement>,
    direction: number,
  ) => {
    const newDuration = this.parsePositiveNumber(this.state.duration)
    if (newDuration !== false) {
      this.onChangeItemDuration(e as any, (newDuration + direction).toString())
    }
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
      if (window.ENV.FEATURES.course_pace_time_selection) {
        this.props.setPaceItemDurationTimeToCompleteCalendarDays(this.props.coursePaceItem.module_item_id, duration, this.props.blackoutDates)
      } else {
        this.props.setPaceItemDuration(this.props.coursePaceItem.module_item_id, duration)
      }
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
    const disabledByBlueprintLock = this.props.blueprintLocked
    const itemChange = this.props.coursePaceItemChanges.find(
      c => c.newValue.module_item_id === this.props.coursePaceItem.module_item_id,
    )
    const durationHasChanged = itemChange?.oldValue?.duration !== itemChange?.newValue.duration

    return (
      <FlaggableNumberInput
        label={
          <ScreenReaderContent>
            {I18n.t('Duration for assignment %{name}', {
              name: this.props.coursePaceItem.assignment_title,
            })}
          </ScreenReaderContent>
        }
        interaction={this.props.isSyncing || disabledByBlueprintLock ? 'disabled' : 'enabled'}
        value={this.state.duration}
        onChange={this.onChangeItemDuration}
        onBlur={this.onBlur}
        onDecrement={e => this.onDecrementOrIncrement(e, -1)}
        onIncrement={e => this.onDecrementOrIncrement(e, 1)}
        showTooltipOn={disabledByBlueprintLock ? ['hover', 'focus'] : []}
        showFlag={durationHasChanged}
      />
    )
  }

  renderDate = () => {
    // change the date format and you'll probably have to change
    // the column width in AssignmentRow
    const due = moment(this.props.dueDate)
    return this.dateFormatter(due.toDate())
  }

  renderTitle() {
    return (
      <Flex alignItems="center">
        <View margin="0 x-small 0 0">{this.renderAssignmentIcon()}</View>
        <div>
          <Text weight="bold">
            <a
              href={this.props.coursePaceItem.assignment_link}
              style={{color: 'inherit', overflowWrap: 'anywhere'}}
            >
              {this.props.coursePaceItem.assignment_title}
            </a>
          </Text>
          {typeof this.props.coursePaceItem.points_possible === 'number' && (
            <div className="course-paces-assignment-row-points-possible">
              <Text size="x-small">
                {I18n.t(
                  {one: '1 pt', other: '%{count} pts'},
                  {count: this.props.coursePaceItem.points_possible},
                )}
              </Text>
            </div>
          )}
          {
            ENV.FEATURES.course_pace_pacing_with_mastery_paths && this.props.coursePaceItem.unreleased && (
              <div>
                <Text size="x-small" color="danger">
                  <IconWarningLine size="x-small" /> {I18n.t("Based on Mastery Path results this assignment may not be assigned to this student.")}
                </Text>
              </div>
            )
          }
        </div>
      </Flex>
    )
  }

  renderSubmissionStatus = () => {
    const { submission_status } = this.props.coursePaceItem
    const isFeatureEnabled = window.ENV.FEATURES.course_pace_pacing_status_labels

    // Not submittable or not due yet, no label needed
    if (!submission_status || !isFeatureEnabled) {
      return null
    }

    let status: string = ''
    switch (submission_status) {
      case 'late':
        status = I18n.t("Late Submission")
        break
      case 'missing':
        status = I18n.t("No Submission")
        break
    }

    return status ? (
      <div style={{whiteSpace: "nowrap", marginTop: 5}}>
        <Text color="danger">
          <IconWarningLine size="x-small" /> {status}
        </Text>
      </div>
    ) : null
  }

  renderMasteryPathsInfo({ isTrigger, releasedLabel }: MasteryPathsData, moduleItemId: string) {
    if (!isTrigger && !releasedLabel) return null;

    return (
      <Flex gap="small" data-testid={`mastery-paths-data-${moduleItemId}`}>
        {
          ENV.FEATURES.course_pace_pacing_with_mastery_paths && this.props.coursePaceItem.unreleased && (
            <Flex.Item>
              <Tooltip renderTip={I18n.t("This student may not have visibility to this assignment based on their Mastery path assessment results.")}>
                <IconOffLine size="x-small" />
              </Tooltip>
            </Flex.Item>
          )
        }
        {isTrigger && moduleItemId && (
          <Flex.Item>
            <Link href={`${ENV.CONTEXT_URL_ROOT}/modules/items/${moduleItemId}/edit_mastery_paths`}>
              {I18n.t('Mastery Paths')}
            </Link>
          </Flex.Item>
        )}
        {releasedLabel && (
          <Flex.Item>
            <Pill data-testid={`${releasedLabel}-${moduleItemId}`}>
              <i className="icon-mastery-paths" /> {releasedLabel}
            </Pill>
          </Flex.Item>
        )}
      </Flex>
    );
  }

  render() {
    const labelMargin = this.props.isStacked ? '0 0 0 small' : undefined

    const componentOverrides = {
      'Table.Cell': {
        background: this.state.hovering ? '#eef7ff' : '#fff',
      },
    }
    const contextType = this.props.context_type

    const coursePaceItem = this.props.coursePaceItem;
    const masteryPathsData: MasteryPathsData = CyoeHelper.getItemData(coursePaceItem.assignment_id, true);

    return (
      <InstUISettingsProvider theme={{componentOverrides}}>
        {/* @ts-expect-error */}
        <Table.Row
          data-testid="pp-module-item-row"
          onMouseEnter={() => this.setState({hovering: true})}
          onMouseLeave={() => this.setState({hovering: false})}
          {...pick(this.props, ['hover', 'isStacked', 'headers'])}
        >
          <Table.Cell data-testid="pp-title-cell">
            <Flex justifyItems="space-between">
              <Flex.Item>
                <View margin={labelMargin}>{this.renderTitle()}</View>
              </Flex.Item>
              <Flex.Item>
                {masteryPathsData && ENV.FEATURES.course_pace_pacing_with_mastery_paths && this.renderMasteryPathsInfo(masteryPathsData, coursePaceItem.module_item_id)}
              </Flex.Item>
            </Flex>
          </Table.Cell>
          <Table.Cell data-testid="pp-duration-cell" textAlign="center">
            <View data-testid="duration-input" margin={labelMargin}>
              {this.renderDurationInput()}
            </View>
          </Table.Cell>
          {this.props.showProjections || this.props.datesVisible ? (
            <Table.Cell data-testid="pp-due-date-cell" textAlign="center">
              <View data-testid="assignment-due-date" margin={labelMargin}>
                <span style={{whiteSpace: this.props.isStacked ? 'normal' : 'nowrap'}}>
                  {this.renderDate()}
                </span>
                {contextType === 'Enrollment' && this.renderSubmissionStatus()}
              </View>
            </Table.Cell>
          ) : (
            <></>
          )}
          <Table.Cell
            data-testid="pp-status-cell"
            textAlign={this.props.isStacked ? 'start' : 'center'}
          >
            <View margin={labelMargin}>{this.renderPublishStatusBadge()}</View>
          </Table.Cell>
        </Table.Row>
      </InstUISettingsProvider>
    )
  }
}

const mapStateToProps = (state: StoreState, props: PassedProps): StoreProps => {
  const coursePace = getCoursePace(state)

  return {
    coursePace,
    excludeWeekends: getExcludeWeekends(state),
    selectedDaysToSkip: getSelectedDaysToSkip(state),
    blueprintLocked: getBlueprintLocked(state),
    coursePaceItemPosition: getCoursePaceItemPosition(state, props),
    blackoutDates: getBlackoutDates(state),
    isSyncing: getSyncing(state),
    showProjections: getShowProjections(state),
    isStudentPace: isStudentPace(state),
    context_type: getSelectedContextType(state),
    coursePaceItemChanges: getCoursePaceItemChanges(state),
  }
}

const ConnectedAssignmentRow = connect(mapStateToProps, {
  setPaceItemDuration: actions.setPaceItemDuration,
  setPaceItemDurationTimeToCompleteCalendarDays: coursePaceActions.setPaceItemDurationTimeToCompleteCalendarDays
})(AssignmentRow)

// This hack allows AssignmentRow to be rendered inside an InstUI Table.Body
ConnectedAssignmentRow.displayName = 'Row'

export default ConnectedAssignmentRow

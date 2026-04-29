/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import React, {Component} from 'react'
import classnames from 'classnames'
import moment from 'moment-timezone'
import {colors} from '@instructure/canvas-theme'
import {InstUISettingsProvider} from '@instructure/emotion'
import {
  AccessibleContent,
  ScreenReaderContent,
  PresentationContent,
} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {Pill} from '@instructure/ui-pill'
import {Avatar} from '@instructure/ui-avatar'
import {Checkbox} from '@instructure/ui-checkbox'
import {Button, IconButton} from '@instructure/ui-buttons'
import {Link} from '@instructure/ui-link'
import {
  IconAssignmentLine,
  IconQuizLine,
  IconAnnouncementLine,
  IconDiscussionLine,
  IconCalendarMonthLine,
  IconDocumentLine,
  IconEditLine,
  IconPeerReviewLine,
  IconWarningLine,
  IconVideoCameraSolid,
  IconVideoCameraLine,
} from '@instructure/ui-icons'
import {arrayOf, bool, number, string, func, shape, object} from 'prop-types'
import {momentObj} from 'react-moment-proptypes'

import NotificationBadge, {MissingIndicator, NewActivityIndicator} from '../NotificationBadge'
import BadgeList from '../BadgeList'
import CalendarEventModal from '../CalendarEventModal'
import {badgeShape, userShape, statusShape, sizeShape, feedbackShape} from '../plannerPropTypes'
// @ts-expect-error TS2305 (typescriptify)
import {getDynamicFullDateAndTime} from '../../utilities/dateUtils'
import {showPillForOverdueStatus} from '../../utilities/statusUtils'
import {assignmentType as getAssignmentType} from '../../utilities/contentUtils'
import {useScope as createI18nScope} from '@canvas/i18n'
import {animatable} from '../../dynamic-ui'
import buildStyle from './style'
import {stripHtmlTags} from '@canvas/util/TextHelper'

const I18n = createI18nScope('planner')

export class PlannerItem_raw extends Component {
  static componentId = 'PlannerItem'

  static propTypes = {
    color: string,
    uniqueId: string.isRequired,
    animatableIndex: number,
    title: string.isRequired,
    points: number,
    date: momentObj,
    address: string,
    dateStyle: string,
    details: string,
    courseName: string,
    completed: bool,
    associated_item: string,
    context: object,
    html_url: string,
    toggleCompletion: func,
    updateTodo: func,
    badges: arrayOf(shape(badgeShape)),
    registerAnimatable: func,
    deregisterAnimatable: func,
    toggleAPIPending: bool,
    status: statusShape,
    newActivity: bool,
    showNotificationBadge: bool,
    currentUser: shape(userShape),
    responsiveSize: sizeShape,
    allDay: bool,
    feedback: shape(feedbackShape),
    location: string,
    endTime: momentObj,
    timeZone: string.isRequired,
    simplifiedControls: bool,
    isMissingItem: bool,
    readOnly: bool,
    onlineMeetingURL: string,
    isObserving: bool,
    newActivityTestId: string,
    missingIndicatorTestId: string,
  }

  static defaultProps = {
    badges: [],
    responsiveSize: 'large',
    allDay: false,
    simplifiedControls: false,
    isMissingItem: false,
    isObserving: false,
  }

  // @ts-expect-error TS7006 (typescriptify)
  constructor(props) {
    super(props)
    this.state = {
      calendarEventModalOpen: false,
      completed: props.completed,
    }
    // @ts-expect-error TS2339 (typescriptify)
    this.style = buildStyle()
  }

  componentDidMount() {
    // @ts-expect-error TS2339 (typescriptify)
    this.props.registerAnimatable?.('item', this, this.props.animatableIndex, [this.props.uniqueId])
  }

  // @ts-expect-error TS7006 (typescriptify)
  UNSAFE_componentWillReceiveProps(nextProps) {
    // @ts-expect-error TS2339 (typescriptify)
    this.props.deregisterAnimatable('item', this, [this.props.uniqueId])
    // @ts-expect-error TS2339 (typescriptify)
    this.props.registerAnimatable('item', this, nextProps.animatableIndex, [nextProps.uniqueId])
    this.setState({
      completed: nextProps.completed,
    })
  }

  componentWillUnmount() {
    // @ts-expect-error TS2339 (typescriptify)
    this.props.deregisterAnimatable('item', this, [this.props.uniqueId])
  }

  // @ts-expect-error TS7006 (typescriptify)
  toDoLinkClick = e => {
    e.preventDefault()
    // @ts-expect-error TS2339 (typescriptify)
    this.props.updateTodo && this.props.updateTodo({updateTodoItem: {...this.props}})
  }

  // @ts-expect-error TS7006 (typescriptify)
  registerRootDivRef = elt => {
    // @ts-expect-error TS2339 (typescriptify)
    this.rootDivRef = elt
  }

  // @ts-expect-error TS7006 (typescriptify)
  registerFocusElementRef = elt => {
    // @ts-expect-error TS2339 (typescriptify)
    this.checkboxRef = elt
  }

  // @ts-expect-error TS7006 (typescriptify)
  getFocusable = which => {
    // @ts-expect-error TS2339 (typescriptify)
    return which === 'update' || which === 'delete' ? this.itemLink : this.checkboxRef
  }

  getScrollable() {
    // @ts-expect-error TS2339 (typescriptify)
    return this.rootDivRef
  }

  getLayout() {
    // @ts-expect-error TS2339 (typescriptify)
    return this.props.responsiveSize
  }

  hasDueTime() {
    // @ts-expect-error TS2339 (typescriptify)
    const associatedItem = this.props.associated_item

    return (
      // @ts-expect-error TS2339 (typescriptify)
      this.props.date && !(associatedItem === 'Announcement' || associatedItem === 'Calendar Event')
    )
  }

  showEndTime() {
    return (
      // @ts-expect-error TS2339 (typescriptify)
      this.props.date &&
      // @ts-expect-error TS2339 (typescriptify)
      !this.props.allDay &&
      // @ts-expect-error TS2339 (typescriptify)
      this.props.endTime &&
      // @ts-expect-error TS2339 (typescriptify)
      !this.props.endTime.isSame(this.props.date)
    )
  }

  hasBadges() {
    // @ts-expect-error TS2339 (typescriptify)
    return this.props.badges && this.props.badges.length && this.props.badges.length > 0
  }

  assignmentType() {
    // @ts-expect-error TS2339 (typescriptify)
    return getAssignmentType(this.props.associated_item)
  }

  // @ts-expect-error TS7006 (typescriptify)
  formatDate = date => {
    // @ts-expect-error TS2339 (typescriptify)
    return this.props.isMissingItem
      ? // @ts-expect-error TS2339 (typescriptify)
        getDynamicFullDateAndTime(date, this.props.timeZone)
      : date.format('LT')
  }

  renderDateField = () => {
    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.date && this.props.date.isValid()) {
      // @ts-expect-error TS2339 (typescriptify)
      if (this.props.allDay) {
        return I18n.t('All Day')
      }

      // @ts-expect-error TS2339 (typescriptify)
      if (this.props.associated_item === 'Calendar Event') {
        if (this.showEndTime()) {
          return I18n.t('%{startTime} to %{endTime}', {
            // @ts-expect-error TS2339 (typescriptify)
            startTime: this.formatDate(this.props.date),
            // @ts-expect-error TS2339 (typescriptify)
            endTime: this.formatDate(this.props.endTime),
          })
        } else {
          // @ts-expect-error TS2339 (typescriptify)
          return this.formatDate(this.props.date)
        }
      }

      if (this.hasDueTime()) {
        // @ts-expect-error TS2339 (typescriptify)
        if (this.props.associated_item === 'Peer Review') {
          // @ts-expect-error TS2339 (typescriptify)
          return I18n.t('Reminder: %{date}', {date: this.formatDate(this.props.date)})
          // @ts-expect-error TS2339 (typescriptify)
        } else if (this.props.dateStyle === 'todo') {
          // @ts-expect-error TS2339 (typescriptify)
          return I18n.t('To Do: %{date}', {date: this.formatDate(this.props.date)})
        } else {
          // @ts-expect-error TS2339 (typescriptify)
          return I18n.t('Due: %{date}', {date: this.formatDate(this.props.date)})
        }
      }

      // @ts-expect-error TS2339 (typescriptify)
      return this.formatDate(this.props.date)
    }
    return null
  }

  linkLabel() {
    const assignmentType = this.assignmentType()
    // @ts-expect-error TS2339 (typescriptify)
    const datetimeformat = this.props.allDay === true ? 'LL' : 'LLLL'
    // @ts-expect-error TS2339 (typescriptify)
    const title = this.props.title
    // @ts-expect-error TS2339 (typescriptify)
    const datetime = this.props.date ? this.props.date.format(datetimeformat) : null

    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.date) {
      // @ts-expect-error TS2339 (typescriptify)
      if (this.props.allDay) {
        return I18n.t('%{assignmentType} %{title}, all day on %{datetime}.', {
          assignmentType,
          title,
          datetime,
        })
      }

      // @ts-expect-error TS2339 (typescriptify)
      if (this.props.associated_item === 'Calendar Event') {
        if (this.showEndTime()) {
          return I18n.t('%{assignmentType} %{title}, at %{datetime} until %{endTime}', {
            assignmentType,
            title,
            datetime,
            // @ts-expect-error TS2339 (typescriptify)
            endTime: this.props.endTime.format('LT'),
          })
        } else {
          return I18n.t('%{assignmentType} %{title}, at %{datetime}.', {
            assignmentType,
            title,
            datetime,
          })
        }
      }

      if (this.hasDueTime()) {
        // @ts-expect-error TS2339 (typescriptify)
        if (this.props.dateStyle === 'todo') {
          return I18n.t('%{assignmentType} %{title} has a to do time at %{datetime}.', {
            assignmentType,
            title,
            datetime,
          })
          // @ts-expect-error TS2339 (typescriptify)
        } else if (this.props.associated_item === 'Peer Review') {
          return I18n.t('%{assignmentType} %{title}, reminder %{datetime}.', {
            assignmentType,
            title,
            datetime,
          })
        } else {
          return I18n.t('%{assignmentType} %{title}, due %{datetime}.', {
            assignmentType,
            title,
            datetime,
          })
        }
      }

      // @ts-expect-error TS2339 (typescriptify)
      if (this.props.associated_item === 'Announcement') {
        return I18n.t('%{assignmentType} %{title} posted %{datetime}.', {
          assignmentType,
          title,
          datetime,
        })
      }
    }
    return I18n.t('%{assignmentType} %{title}.', {
      assignmentType,
      title,
    })
  }

  openCalendarEventModal = () => {
    this.setState({calendarEventModalOpen: true})
  }

  closeCalendarEventModal = () => {
    this.setState({calendarEventModalOpen: false})
  }

  renderIcon = () => {
    // @ts-expect-error TS2339 (typescriptify)
    const currentUser = this.props.currentUser || {}

    // @ts-expect-error TS2339 (typescriptify)
    switch (this.props.associated_item) {
      case 'Assignment':
        return <IconAssignmentLine />
      case 'Quiz':
        return <IconQuizLine />
      case 'Discussion':
        return <IconDiscussionLine />
      case 'Announcement':
        return <IconAnnouncementLine />
      case 'Calendar Event':
        return <IconCalendarMonthLine />
      case 'Page':
        return <IconDocumentLine />
      case 'Peer Review':
        return <IconPeerReviewLine />
      case 'Discussion Checkpoint':
        return <IconDiscussionLine />
      default:
        return (
          <Avatar
            name={currentUser.displayName || '?'}
            src={currentUser.avatarUrl}
            size="small"
            data-fs-exclude={true}
          />
        )
    }
  }

  renderCalendarEventModal() {
    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.associated_item !== 'Calendar Event') return null
    return (
      <CalendarEventModal
        // @ts-expect-error TS2339 (typescriptify)
        open={this.state.calendarEventModalOpen}
        requestClose={this.closeCalendarEventModal}
        // @ts-expect-error TS2339 (typescriptify)
        title={this.props.title}
        // @ts-expect-error TS2339 (typescriptify)
        html_url={this.props.html_url}
        // @ts-expect-error TS2339 (typescriptify)
        courseName={this.props.courseName}
        // @ts-expect-error TS2339 (typescriptify)
        currentUser={this.props.currentUser}
        // @ts-expect-error TS2339 (typescriptify)
        location={this.props.location}
        // @ts-expect-error TS2339 (typescriptify)
        address={this.props.address}
        // @ts-expect-error TS2339 (typescriptify)
        details={this.props.details}
        // @ts-expect-error TS2339 (typescriptify)
        startTime={this.props.date}
        // @ts-expect-error TS2339 (typescriptify)
        endTime={this.props.endTime}
        // @ts-expect-error TS2339 (typescriptify)
        allDay={!!this.props.allDay}
        // @ts-expect-error TS2339 (typescriptify)
        timeZone={this.props.timeZone}
      />
    )
  }

  renderTitle() {
    // @ts-expect-error TS2339 (typescriptify)
    if (['To Do', 'Calendar Event'].includes(this.props.associated_item)) {
      return (
        // @ts-expect-error TS2339 (typescriptify)
        <div className={this.style.classNames.title} style={{position: 'relative'}}>
          <Link
            isWithinText={false}
            themeOverride={{
              // @ts-expect-error TS2769 (typescriptify)
              mediumPaddingHorizontal: '0',
              // @ts-expect-error TS2339 (typescriptify)
              linkColor: this.props.simplifiedControls ? colors.contrasts.grey125125 : undefined,
              // @ts-expect-error TS2339 (typescriptify)
              linkHoverColor: this.props.simplifiedControls
                ? colors.contrasts.grey125125
                : undefined,
            }}
            elementRef={link => {
              // @ts-expect-error TS2339 (typescriptify)
              this.itemLink = link
            }}
            onClick={
              // @ts-expect-error TS2339 (typescriptify)
              this.props.associated_item === 'To Do'
                ? this.toDoLinkClick
                : this.openCalendarEventModal
            }
            // @ts-expect-error TS2339 (typescriptify)
            readOnly={this.props.readOnly}
          >
            <ScreenReaderContent>{this.linkLabel()}</ScreenReaderContent>
            {/* @ts-expect-error TS2339 (typescriptify) */}
            <PresentationContent>{this.props.title}</PresentationContent>
          </Link>
          {this.renderCalendarEventModal()}
        </div>
      )
    }

    return (
      <Link
        // @ts-expect-error TS2339 (typescriptify)
        href={this.props.html_url}
        isWithinText={false}
        themeOverride={{
          // @ts-expect-error TS2339 (typescriptify)
          ...(this.props.simplifiedControls ? {color: colors.contrasts.grey125125} : {}),
          // @ts-expect-error TS2339 (typescriptify)
          ...(this.props.simplifiedControls ? {linkHoverColor: colors.contrasts.grey125125} : {}),
        }}
        elementRef={link => {
          // @ts-expect-error TS2339 (typescriptify)
          this.itemLink = link
        }}
        // @ts-expect-error TS2339 (typescriptify)
        interaction={this.props.readOnly ? 'disabled' : 'enabled'}
      >
        <ScreenReaderContent>{this.linkLabel()}</ScreenReaderContent>
        {/* @ts-expect-error TS2339 (typescriptify) */}
        <PresentationContent>{this.props.title}</PresentationContent>
      </Link>
    )
  }

  renderBadges = () => {
    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.badges.length) {
      return (
        <BadgeList>
          {/* @ts-expect-error TS2339,TS7006 (typescriptify) */}
          {this.props.badges.map(b => (
            <Pill key={b.id} color={b.variant}>
              {b.text}
            </Pill>
          ))}
        </BadgeList>
      )
    }
    return null
  }

  renderItemSubMetric = () => {
    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.points) {
      return (
        // @ts-expect-error TS2339 (typescriptify)
        <div className={this.style.classNames.score}>
          {/* @ts-expect-error TS2339 (typescriptify) */}
          <Text size="large">{this.props.points}</Text>
          <Text size="x-small">
            &nbsp;
            {I18n.t('pts')}
          </Text>
        </div>
      )
    }
    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.associated_item === 'To Do' && !this.props.isObserving) {
      return (
        // @ts-expect-error TS2339 (typescriptify)
        <div className={this.style.classNames.editButton}>
          <InstUISettingsProvider
            theme={{
              componentOverrides: {
                IconButton: {
                  // @ts-expect-error TS2339,TS2353 (typescriptify)
                  iconColor: this.props.simplifiedControls ? undefined : this.props.color,
                },
              },
            }}
          >
            <IconButton
              data-testid="edit-event-button"
              withBorder={false}
              withBackground={false}
              renderIcon={IconEditLine}
              onClick={this.toDoLinkClick}
              screenReaderLabel={I18n.t('Edit')}
            />
          </InstUISettingsProvider>
        </div>
      )
    }
    return null
  }

  renderItemMetrics = () => {
    const secondaryClasses = classnames(
      // @ts-expect-error TS2339 (typescriptify)
      this.style.classNames.secondary,
      // @ts-expect-error TS2339 (typescriptify)
      !this.hasBadges() ? this.style.classNames.secondary_no_badges : '',
    )
    // @ts-expect-error TS2339 (typescriptify)
    const metricsClasses = classnames(this.style.classNames.metrics, {
      // @ts-expect-error TS2339 (typescriptify)
      [this.style.classNames.with_end_time]: this.showEndTime(),
    })
    return (
      <div className={secondaryClasses}>
        {/* @ts-expect-error TS2339 (typescriptify) */}
        <div className={this.style.classNames.badges}>{this.renderBadges()}</div>
        <div className={metricsClasses}>
          {this.renderItemSubMetric()}
          {/* @ts-expect-error TS2339 (typescriptify) */}
          <div className={this.style.classNames.due}>
            <Text size="x-small">
              <PresentationContent>{this.renderDateField()}</PresentationContent>
            </Text>
          </div>
        </div>
        {/* @ts-expect-error TS2339 (typescriptify) */}
        {this.props.responsiveSize !== 'small' && this.renderOnlineMeeting()}
      </div>
    )
  }

  renderType = () => {
    // @ts-expect-error TS2339 (typescriptify)
    if (!this.props.associated_item) {
      // @ts-expect-error TS2339 (typescriptify)
      return I18n.t('%{course} TO DO', {course: this.props.courseName || ''})
    } else {
      // @ts-expect-error TS2339 (typescriptify)
      return `${this.props.courseName || ''} ${this.assignmentType()}`
    }
  }

  renderCourseName = () => {
    // @ts-expect-error TS2339 (typescriptify)
    if (!this.props.isMissingItem || !this.props.courseName) return null

    return (
      <Text
        size="x-small"
        weight="bold"
        color="primary"
        letterSpacing="expanded"
        transform="uppercase"
        // @ts-expect-error TS2339 (typescriptify)
        themeOverride={{primaryColor: this.props.color}}
        data-testid="MissingAssignments-CourseName"
      >
        {/* @ts-expect-error TS2339 (typescriptify) */}
        {this.props.courseName}
      </Text>
    )
  }

  renderItemDetails = () => {
    return (
      <div
        className={classnames(
          // @ts-expect-error TS2339 (typescriptify)
          this.style.classNames.details,
          // @ts-expect-error TS2339 (typescriptify)
          !this.hasBadges() ? this.style.classNames.details_no_badges : '',
        )}
      >
        {/* @ts-expect-error TS2339 (typescriptify) */}
        {!this.props.simplifiedControls && (
          // @ts-expect-error TS2339 (typescriptify)
          <div className={this.style.classNames.type}>
            <Text size="x-small" color="secondary">
              {this.renderType()}
            </Text>
          </div>
        )}
        {this.renderMoreDetails()}
      </div>
    )
  }

  renderMoreDetails() {
    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.responsiveSize === 'small') {
      return (
        <>
          {/* @ts-expect-error TS2339 (typescriptify) */}
          <div className={this.style.classNames.moreDetails}>
            {this.renderTitle()}
            {this.renderOnlineMeeting()}
          </div>
          {this.renderCourseName()}
        </>
      )
    }

    return (
      <>
        {this.renderTitle()}
        {this.renderCourseName()}
      </>
    )
  }

  renderNotificationBadge() {
    // @ts-expect-error TS2339 (typescriptify)
    if (!this.props.showNotificationBadge) {
      return null
    }

    // @ts-expect-error TS2339 (typescriptify)
    const newItem = this.props.newActivity
    let missing = false
    if (
      // @ts-expect-error TS2339 (typescriptify)
      showPillForOverdueStatus('missing', {status: this.props.status, context: this.props.context})
    ) {
      missing = true
    }

    if (newItem || missing) {
      const IndicatorComponent = newItem ? NewActivityIndicator : MissingIndicator
      // @ts-expect-error TS2339 (typescriptify)
      const testId = newItem ? this.props.newActivityTestId : this.props.missingIndicatorTestId
      return (
        // @ts-expect-error TS2339 (typescriptify)
        <NotificationBadge responsiveSize={this.props.responsiveSize}>
          {/* @ts-expect-error TS2339 (typescriptify) */}
          <div className={this.style.classNames.activityIndicator}>
            <IndicatorComponent
              // @ts-expect-error TS2339 (typescriptify)
              title={this.props.title}
              // @ts-expect-error TS2339 (typescriptify)
              itemIds={[this.props.uniqueId]}
              // @ts-expect-error TS2339 (typescriptify)
              animatableIndex={this.props.animatableIndex}
              getFocusable={this.getFocusable}
              testId={testId}
            />
          </div>
        </NotificationBadge>
      )
    } else {
      // @ts-expect-error TS2339 (typescriptify)
      return <NotificationBadge responsiveSize={this.props.responsiveSize} />
    }
  }

  getCheckboxTheme = () => {
    // @ts-expect-error TS2339 (typescriptify)
    return this.props.simplifiedControls
      ? {}
      : {
          // @ts-expect-error TS2339 (typescriptify)
          checkedBackground: this.props.color,
          // @ts-expect-error TS2339 (typescriptify)
          checkedBorderColor: this.props.color,
          // @ts-expect-error TS2339 (typescriptify)
          borderColor: this.props.color,
          // @ts-expect-error TS2339 (typescriptify)
          hoverBorderColor: this.props.color,
        }
  }

  renderExtraInfo() {
    // @ts-expect-error TS2339 (typescriptify)
    const feedback = this.props.feedback
    if (feedback) {
      const comment = feedback.is_media
        ? I18n.t('You have media feedback.')
        : stripHtmlTags(feedback.comment)
      return (
        // @ts-expect-error TS2339 (typescriptify)
        <div className={this.style.classNames.feedback}>
          {/* @ts-expect-error TS2339 (typescriptify) */}
          <span className={this.style.classNames.feedbackAvatar}>
            <Avatar
              name={feedback.author_name || '?'}
              src={feedback.author_avatar_url}
              size="small"
              data-fs-exclude={true}
            />
          </span>
          {/* @ts-expect-error TS2339 (typescriptify) */}
          <span className={this.style.classNames.feedbackComment} data-testid="feedback-comment">
            <Text fontStyle="italic">{comment}</Text>
          </span>
        </div>
      )
    }
    // @ts-expect-error TS2339 (typescriptify)
    const location = this.props.location
    if (location) {
      return (
        // @ts-expect-error TS2339 (typescriptify)
        <div className={this.style.classNames.location}>
          <Text>{location}</Text>
        </div>
      )
    }
    return null
  }

  renderCompletedCheckbox() {
    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.isMissingItem) {
      return (
        // @ts-expect-error TS2339 (typescriptify)
        <div className={this.style.classNames.completed}>
          <IconWarningLine color="error" />
        </div>
      )
    }

    const assignmentType = this.assignmentType()
    // @ts-expect-error TS2339 (typescriptify)
    const checkboxLabel = this.state.completed
      ? I18n.t('%{assignmentType} %{title} is marked as done.', {
          assignmentType,
          // @ts-expect-error TS2339 (typescriptify)
          title: this.props.title,
        })
      : I18n.t('%{assignmentType} %{title} is not marked as done.', {
          assignmentType,
          // @ts-expect-error TS2339 (typescriptify)
          title: this.props.title,
        })

    return (
      // @ts-expect-error TS2339 (typescriptify)
      <div className={this.style.classNames.completed}>
        <InstUISettingsProvider
          theme={{
            componentOverrides: {
              CheckboxFacade: this.getCheckboxTheme(),
            },
          }}
        >
          <Checkbox
            data-testid="planner-item-completed-checkbox"
            ref={this.registerFocusElementRef}
            label={<ScreenReaderContent>{checkboxLabel}</ScreenReaderContent>}
            // @ts-expect-error TS2339 (typescriptify)
            checked={this.props.toggleAPIPending ? !this.state.completed : this.state.completed}
            // @ts-expect-error TS2339 (typescriptify)
            onChange={this.props.toggleCompletion}
            // @ts-expect-error TS2339 (typescriptify)
            disabled={this.props.toggleAPIPending || this.props.isObserving}
            // @ts-expect-error TS2339 (typescriptify)
            readOnly={this.props.readOnly}
          />
        </InstUISettingsProvider>
      </div>
    )
  }

  renderOnlineMeeting() {
    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.onlineMeetingURL) {
      const now = moment()
      const enabled =
        // @ts-expect-error TS2339 (typescriptify)
        (this.props.allDay && now.isSame(this.props.date, 'day')) || // an all day event today
        // @ts-expect-error TS2339 (typescriptify)
        (this.props.endTime && now.isBetween(this.props.date, this.props.endTime)) || // during an event
        // @ts-expect-error TS2339 (typescriptify)
        (!this.props.endTime && now.isSame(this.props.date, 'day') && now > this.props.date) // after start time today for an event with no end time
      const srlabel = enabled ? I18n.t('join active online meeting') : I18n.t('join online meeting')
      return (
        // @ts-expect-error TS2339 (typescriptify)
        <div className={this.style.classNames.onlineMeeting}>
          <Button
            data-testid={enabled ? 'join-button-hot' : 'join-button'}
            size="small"
            color={enabled ? 'success' : 'secondary'}
            // @ts-expect-error TS2339 (typescriptify)
            margin={this.props.responsiveSize === 'small' ? '0' : '0 0 0 x-small'}
            // @ts-expect-error TS2769 (typescriptify)
            renderIcon={enabled ? IconVideoCameraSolid : IconVideoCameraLine}
            onClick={() => {
              // @ts-expect-error TS2339 (typescriptify)
              window.open(this.props.onlineMeetingURL)
            }}
          >
            <AccessibleContent alt={srlabel}>{I18n.t('Join')}</AccessibleContent>
          </Button>
        </div>
      )
    }
  }

  render() {
    return (
      <>
        {/* @ts-expect-error TS2339 (typescriptify) */}
        <style>{this.style.css}</style>
        <div
          data-testid="planner-item-raw"
          className={classnames(
            // @ts-expect-error TS2339 (typescriptify)
            this.style.classNames.root,
            // @ts-expect-error TS2339 (typescriptify)
            this.style.classNames[this.getLayout()],
            'planner-item',
            {
              // @ts-expect-error TS2339 (typescriptify)
              [this.style.classNames.missingItem]: this.props.isMissingItem,
            },
            // @ts-expect-error TS2339 (typescriptify)
            this.props.simplifiedControls ? this.style.classNames.k5Layout : '',
          )}
          ref={this.registerRootDivRef}
        >
          {this.renderNotificationBadge()}
          {this.renderCompletedCheckbox()}
          <div
            className={
              // @ts-expect-error TS2339 (typescriptify)
              this.props.associated_item === 'To Do'
                ? // @ts-expect-error TS2339 (typescriptify)
                  this.style.classNames.avatar
                : // @ts-expect-error TS2339 (typescriptify)
                  this.style.classNames.icon
            }
            // @ts-expect-error TS2339 (typescriptify)
            style={{color: this.props.simplifiedControls ? undefined : this.props.color}}
            aria-hidden="true"
          >
            {this.renderIcon()}
          </div>
          {/* @ts-expect-error TS2339 (typescriptify) */}
          <div className={this.style.classNames.layout}>
            {/* @ts-expect-error TS2339 (typescriptify) */}
            <div className={this.style.classNames.innerLayout}>
              {this.renderItemDetails()}
              {this.renderItemMetrics()}
            </div>
            {this.renderExtraInfo()}
          </div>
        </div>
      </>
    )
  }
}

// @ts-expect-error TS2339 (typescriptify)
PlannerItem_raw.displayName = 'PlannerItem_raw'

const AnimatablePlannerItem = animatable(PlannerItem_raw)
// @ts-expect-error TS2339 (typescriptify)
AnimatablePlannerItem.theme = PlannerItem_raw.theme
export default AnimatablePlannerItem

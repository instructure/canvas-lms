/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that they will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import React, {Component} from 'react'
import classnames from 'classnames'
import {colors} from '@instructure/canvas-theme'
import {themeable, ApplyTheme} from '@instructure/ui-themeable'
import {Text} from '@instructure/ui-text'
import {Pill} from '@instructure/ui-pill'
import {Avatar} from '@instructure/ui-avatar'
import {Checkbox, CheckboxFacade} from '@instructure/ui-checkbox'
import {ScreenReaderContent, PresentationContent} from '@instructure/ui-a11y-content'
import {Button} from '@instructure/ui-buttons'
import {
  IconAssignmentLine,
  IconQuizLine,
  IconAnnouncementLine,
  IconDiscussionLine,
  IconCalendarMonthLine,
  IconDocumentLine,
  IconEditLine,
  IconPeerReviewLine,
  IconWarningLine
} from '@instructure/ui-icons'
import {arrayOf, bool, number, string, func, shape, object} from 'prop-types'
import {momentObj} from 'react-moment-proptypes'
// eslint-disable-next-line import/no-named-as-default
import NotificationBadge, {MissingIndicator, NewActivityIndicator} from '../NotificationBadge'
import BadgeList from '../BadgeList'
import CalendarEventModal from '../CalendarEventModal'
import responsiviser from '../responsiviser'
import styles from './styles.css'
import theme from './theme'
import {badgeShape, userShape, statusShape, sizeShape, feedbackShape} from '../plannerPropTypes'
import {showPillForOverdueStatus} from '../../utilities/statusUtils'
import formatMessage from '../../format-message'
import {animatable} from '../../dynamic-ui'

export class PlannerItem extends Component {
  static propTypes = {
    color: string,
    id: string.isRequired,
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
    overrideId: string,
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
    isMissingItem: bool
  }

  static defaultProps = {
    badges: [],
    responsiveSize: 'large',
    allDay: false,
    simplifiedControls: false,
    isMissingItem: false
  }

  constructor(props) {
    super(props)
    this.state = {
      calendarEventModalOpen: false,
      completed: props.completed
    }
  }

  componentDidMount() {
    this.props.registerAnimatable('item', this, this.props.animatableIndex, [this.props.uniqueId])
  }

  UNSAFE_componentWillReceiveProps(nextProps) {
    this.props.deregisterAnimatable('item', this, [this.props.uniqueId])
    this.props.registerAnimatable('item', this, nextProps.animatableIndex, [nextProps.uniqueId])
    this.setState({
      completed: nextProps.completed
    })
  }

  componentWillUnmount() {
    this.props.deregisterAnimatable('item', this, [this.props.uniqueId])
  }

  toDoLinkClick = e => {
    e.preventDefault()
    this.props.updateTodo && this.props.updateTodo({updateTodoItem: {...this.props}})
  }

  registerRootDivRef = elt => {
    this.rootDivRef = elt
  }

  registerFocusElementRef = elt => {
    this.checkboxRef = elt
  }

  getFocusable = which => {
    return which === 'update' || which === 'delete' ? this.itemLink : this.checkboxRef
  }

  getScrollable() {
    return this.rootDivRef
  }

  getLayout() {
    return this.props.responsiveSize
  }

  hasDueTime() {
    return (
      this.props.date &&
      !(
        this.props.associated_item === 'Announcement' ||
        this.props.associated_item === 'Calendar Event'
      )
    )
  }

  showEndTime() {
    return (
      this.props.date &&
      !this.props.allDay &&
      this.props.endTime &&
      !this.props.endTime.isSame(this.props.date)
    )
  }

  hasBadges() {
    return this.props.badges && this.props.badges.length && this.props.badges.length > 0
  }

  assignmentType() {
    switch (this.props.associated_item) {
      case 'Quiz':
        return formatMessage('Quiz')
      case 'Discussion':
        return formatMessage('Discussion')
      case 'Assignment':
        return formatMessage('Assignment')
      case 'Page':
        return formatMessage('Page')
      case 'Announcement':
        return formatMessage('Announcement')
      case 'To Do':
        return formatMessage('To Do')
      case 'Calendar Event':
        return formatMessage('Calendar Event')
      case 'Peer Review':
        return formatMessage('Peer Review')
      default:
        return formatMessage('Task')
    }
  }

  renderDateField = () => {
    if (this.props.date) {
      if (this.props.allDay) {
        return formatMessage('All Day')
      }

      if (this.props.associated_item === 'Calendar Event') {
        if (this.showEndTime()) {
          return formatMessage('{startTime} to {endTime}', {
            startTime: this.props.date.format('LT'),
            endTime: this.props.endTime.format('LT')
          })
        } else {
          return formatMessage(this.props.date.format('LT'))
        }
      }

      if (this.hasDueTime()) {
        if (this.props.associated_item === 'Peer Review') {
          return formatMessage('Reminder: {date}', {date: this.props.date.format('LT')})
        } else if (this.props.dateStyle === 'todo') {
          return formatMessage('To Do: {date}', {date: this.props.date.format('LT')})
        } else {
          return formatMessage('Due: {date}', {date: this.props.date.format('LT')})
        }
      }

      return this.props.date.format('LT')
    }
    return null
  }

  linkLabel() {
    const assignmentType = this.assignmentType()
    const datetimeformat = this.props.allDay === true ? 'LL' : 'LLLL'
    const params = {
      assignmentType,
      title: this.props.title,
      datetime: this.props.date ? this.props.date.format(datetimeformat) : null
    }

    if (this.props.date) {
      if (this.props.allDay) {
        return formatMessage('{assignmentType} {title}, all day on {datetime}.', params)
      }

      if (this.props.associated_item === 'Calendar Event') {
        if (this.showEndTime()) {
          params.endTime = this.props.endTime.format('LT')
          return formatMessage('{assignmentType} {title}, at {datetime} until {endTime}', params)
        } else {
          return formatMessage('{assignmentType} {title}, at {datetime}.', params)
        }
      }

      if (this.hasDueTime()) {
        if (this.props.dateStyle === 'todo') {
          return formatMessage('{assignmentType} {title} has a to do time at {datetime}.', params)
        } else if (this.props.associated_item === 'Peer Review') {
          return formatMessage('{assignmentType} {title}, reminder {datetime}.', params)
        } else {
          return formatMessage('{assignmentType} {title}, due {datetime}.', params)
        }
      }

      if (this.props.associated_item === 'Announcement') {
        return formatMessage('{assignmentType} {title} posted {datetime}.', params)
      }
    }
    return formatMessage('{assignmentType} {title}.', params)
  }

  openCalendarEventModal = () => {
    this.setState({calendarEventModalOpen: true})
  }

  closeCalendarEventModal = () => {
    this.setState({calendarEventModalOpen: false})
  }

  renderIcon = () => {
    const currentUser = this.props.currentUser || {}

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
      default:
        return (
          <Avatar
            name={currentUser.displayName || '?'}
            src={currentUser.avatarUrl}
            size="small"
            data-fs-exclude
          />
        )
    }
  }

  renderCalendarEventModal() {
    if (this.props.associated_item !== 'Calendar Event') return null
    return (
      <CalendarEventModal
        open={this.state.calendarEventModalOpen}
        requestClose={this.closeCalendarEventModal}
        title={this.props.title}
        html_url={this.props.html_url}
        courseName={this.props.courseName}
        currentUser={this.props.currentUser}
        location={this.props.location}
        address={this.props.address}
        details={this.props.details}
        startTime={this.props.date}
        endTime={this.props.endTime}
        allDay={!!this.props.allDay}
        timeZone={this.props.timeZone}
      />
    )
  }

  renderTitle() {
    const linkProps = {}
    if (this.props.associated_item === 'To Do') {
      linkProps.onClick = this.toDoLinkClick
    }
    if (this.props.associated_item === 'Calendar Event') {
      linkProps.onClick = this.openCalendarEventModal
    } else {
      linkProps.href = this.props.html_url
    }

    return (
      <div className={styles.title} style={{position: 'relative'}}>
        <Button
          variant="link"
          theme={{
            mediumPadding: '0',
            mediumHeight: 'normal',
            linkColor: this.props.simplifiedControls ? colors.licorice : undefined,
            linkHoverColor: this.props.simplifiedControls ? colors.licorice : undefined
          }}
          buttonRef={link => {
            this.itemLink = link
          }}
          {...linkProps}
        >
          <ScreenReaderContent>{this.linkLabel()}</ScreenReaderContent>
          <PresentationContent>{this.props.title}</PresentationContent>
        </Button>
        {this.renderCalendarEventModal()}
      </div>
    )
  }

  renderBadges = () => {
    if (this.props.badges.length) {
      return (
        <BadgeList>
          {this.props.badges.map(b => (
            <Pill key={b.id} text={b.text} variant={b.variant} />
          ))}
        </BadgeList>
      )
    }
    return null
  }

  renderItemSubMetric = () => {
    if (this.props.points) {
      return (
        <div className={styles.score}>
          <Text size="large">{this.props.points}</Text>
          <Text size="x-small">
            &nbsp;
            {formatMessage('pts')}
          </Text>
        </div>
      )
    }
    if (this.props.associated_item === 'To Do') {
      return (
        <div className={styles.editButton}>
          <ApplyTheme
            theme={{
              [Button.theme]: {
                iconColor: this.props.simplifiedControls ? undefined : this.props.color
              }
            }}
          >
            <Button variant="icon" icon={IconEditLine} onClick={this.toDoLinkClick}>
              <ScreenReaderContent>{formatMessage('Edit')}</ScreenReaderContent>
            </Button>
          </ApplyTheme>
        </div>
      )
    }
    return null
  }

  renderItemMetrics = () => {
    const secondaryClasses = classnames(
      styles.secondary,
      !this.hasBadges() ? styles.secondary_no_badges : ''
    )
    const metricsClasses = classnames(styles.metrics, {[styles.with_end_time]: this.showEndTime()})
    return (
      <div className={secondaryClasses}>
        <div className={styles.badges}>{this.renderBadges()}</div>
        <div className={metricsClasses}>
          {this.renderItemSubMetric()}
          <div className={styles.due}>
            <Text size="x-small">
              <PresentationContent>{this.renderDateField()}</PresentationContent>
            </Text>
          </div>
        </div>
      </div>
    )
  }

  renderType = () => {
    if (!this.props.associated_item) {
      return formatMessage('{course} TO DO', {course: this.props.courseName || ''})
    } else {
      return `${this.props.courseName || ''} ${this.assignmentType()}`
    }
  }

  renderCourseName = () => {
    if (!this.props.isMissingItem || !this.props.courseName) return null

    return (
      <Text
        size="x-small"
        weight="bold"
        color="primary"
        letterSpacing="expanded"
        transform="uppercase"
        theme={{primaryColor: this.props.color}}
        data-testid="MissingAssignments-CourseName"
      >
        {this.props.courseName}
      </Text>
    )
  }

  renderItemDetails = () => {
    return (
      <div
        className={classnames(styles.details, !this.hasBadges() ? styles.details_no_badges : '')}
      >
        {!this.props.simplifiedControls && (
          <div className={styles.type}>
            <Text size="x-small" color="secondary">
              {this.renderType()}
            </Text>
          </div>
        )}
        {this.renderTitle()}
        {this.renderCourseName()}
      </div>
    )
  }

  renderNotificationBadge() {
    if (!this.props.showNotificationBadge) {
      return null
    }

    const newItem = this.props.newActivity
    let missing = false
    if (
      showPillForOverdueStatus('missing', {status: this.props.status, context: this.props.context})
    ) {
      missing = true
    }

    if (newItem || missing) {
      const IndicatorComponent = newItem ? NewActivityIndicator : MissingIndicator
      return (
        <NotificationBadge responsiveSize={this.props.responsiveSize}>
          <div className={styles.activityIndicator}>
            <IndicatorComponent
              title={this.props.title}
              itemIds={[this.props.uniqueId]}
              animatableIndex={this.props.animatableIndex}
              getFocusable={this.getFocusable}
            />
          </div>
        </NotificationBadge>
      )
    } else {
      return <NotificationBadge responsiveSize={this.props.responsiveSize} />
    }
  }

  getCheckboxTheme = () => {
    return this.props.simplifiedControls
      ? {}
      : {
          checkedBackground: this.props.color,
          checkedBorderColor: this.props.color,
          borderColor: this.props.color,
          hoverBorderColor: this.props.color
        }
  }

  renderExtraInfo() {
    const feedback = this.props.feedback
    if (feedback) {
      const comment = feedback.is_media
        ? formatMessage('You have media feedback.')
        : feedback.comment
      return (
        <div className={styles.feedback}>
          <span className={styles.feedbackAvatar}>
            <Avatar
              name={feedback.author_name || '?'}
              src={feedback.author_avatar_url}
              size="small"
              data-fs-exclude
            />
          </span>
          <span className={styles.feedbackComment}>
            <Text fontStyle="italic">{comment}</Text>
          </span>
        </div>
      )
    }
    const location = this.props.location
    if (location) {
      return (
        <div className={styles.location}>
          <Text>{location}</Text>
        </div>
      )
    }
    return null
  }

  renderCompletedCheckbox() {
    if (this.props.isMissingItem) {
      return (
        <div className={styles.completed}>
          <IconWarningLine color="error" />
        </div>
      )
    }

    const assignmentType = this.assignmentType()
    const checkboxLabel = this.state.completed
      ? formatMessage('{assignmentType} {title} is marked as done.', {
          assignmentType,
          title: this.props.title
        })
      : formatMessage('{assignmentType} {title} is not marked as done.', {
          assignmentType,
          title: this.props.title
        })

    return (
      <div className={styles.completed}>
        <ApplyTheme
          theme={{
            [CheckboxFacade.theme]: this.getCheckboxTheme()
          }}
        >
          <Checkbox
            ref={this.registerFocusElementRef}
            label={<ScreenReaderContent>{checkboxLabel}</ScreenReaderContent>}
            checked={this.props.toggleAPIPending ? !this.state.completed : this.state.completed}
            onChange={this.props.toggleCompletion}
            disabled={this.props.toggleAPIPending}
          />
        </ApplyTheme>
      </div>
    )
  }

  render() {
    return (
      <div
        className={classnames(styles.root, styles[this.getLayout()], 'planner-item', {
          [styles.missingItem]: this.props.isMissingItem
        })}
        ref={this.registerRootDivRef}
      >
        {this.renderNotificationBadge()}
        {this.renderCompletedCheckbox()}
        <div
          className={this.props.associated_item === 'To Do' ? styles.avatar : styles.icon}
          style={{color: this.props.simplifiedControls ? undefined : this.props.color}}
          aria-hidden="true"
        >
          {this.renderIcon()}
        </div>
        <div className={styles.layout}>
          <div className={styles.innerLayout}>
            {this.renderItemDetails()}
            {this.renderItemMetrics()}
          </div>
          {this.renderExtraInfo()}
        </div>
      </div>
    )
  }
}

const ResponsivePlannerItem = responsiviser()(PlannerItem)
const ThemeablePlannerItem = themeable(theme, styles)(ResponsivePlannerItem)
const AnimatablePlannerItem = animatable(ThemeablePlannerItem)
AnimatablePlannerItem.theme = ThemeablePlannerItem.theme
export default AnimatablePlannerItem

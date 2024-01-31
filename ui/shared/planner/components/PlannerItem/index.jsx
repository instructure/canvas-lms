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
// eslint-disable-next-line import/no-named-as-default
import NotificationBadge, {MissingIndicator, NewActivityIndicator} from '../NotificationBadge'
import BadgeList from '../BadgeList'
import CalendarEventModal from '../CalendarEventModal'
import {badgeShape, userShape, statusShape, sizeShape, feedbackShape} from '../plannerPropTypes'
import {getDynamicFullDateAndTime} from '../../utilities/dateUtils'
import {showPillForOverdueStatus} from '../../utilities/statusUtils'
import {assignmentType as getAssignmentType} from '../../utilities/contentUtils'
import {useScope as useI18nScope} from '@canvas/i18n'
import {animatable} from '../../dynamic-ui'
import buildStyle from './style'

const I18n = useI18nScope('planner')

export class PlannerItem_raw extends Component {
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
  }

  static defaultProps = {
    badges: [],
    responsiveSize: 'large',
    allDay: false,
    simplifiedControls: false,
    isMissingItem: false,
    isObserving: false,
  }

  constructor(props) {
    super(props)
    this.state = {
      calendarEventModalOpen: false,
      completed: props.completed,
    }
    this.style = buildStyle()
  }

  componentDidMount() {
    this.props.registerAnimatable?.('item', this, this.props.animatableIndex, [this.props.uniqueId])
  }

  UNSAFE_componentWillReceiveProps(nextProps) {
    this.props.deregisterAnimatable('item', this, [this.props.uniqueId])
    this.props.registerAnimatable('item', this, nextProps.animatableIndex, [nextProps.uniqueId])
    this.setState({
      completed: nextProps.completed,
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
    return getAssignmentType(this.props.associated_item)
  }

  formatDate = date => {
    return this.props.isMissingItem
      ? getDynamicFullDateAndTime(date, this.props.timeZone)
      : date.format('LT')
  }

  renderDateField = () => {
    if (this.props.date && this.props.date.isValid()) {
      if (this.props.allDay) {
        return I18n.t('All Day')
      }

      if (this.props.associated_item === 'Calendar Event') {
        if (this.showEndTime()) {
          return I18n.t('%{startTime} to %{endTime}', {
            startTime: this.formatDate(this.props.date),
            endTime: this.formatDate(this.props.endTime),
          })
        } else {
          return this.formatDate(this.props.date)
        }
      }

      if (this.hasDueTime()) {
        if (this.props.associated_item === 'Peer Review') {
          return I18n.t('Reminder: %{date}', {date: this.formatDate(this.props.date)})
        } else if (this.props.dateStyle === 'todo') {
          return I18n.t('To Do: %{date}', {date: this.formatDate(this.props.date)})
        } else {
          return I18n.t('Due: %{date}', {date: this.formatDate(this.props.date)})
        }
      }

      return this.formatDate(this.props.date)
    }
    return null
  }

  linkLabel() {
    const assignmentType = this.assignmentType()
    const datetimeformat = this.props.allDay === true ? 'LL' : 'LLLL'
    const title = this.props.title
    const datetime = this.props.date ? this.props.date.format(datetimeformat) : null

    if (this.props.date) {
      if (this.props.allDay) {
        return I18n.t('%{assignmentType} %{title}, all day on %{datetime}.', {
          assignmentType,
          title,
          datetime,
        })
      }

      if (this.props.associated_item === 'Calendar Event') {
        if (this.showEndTime()) {
          return I18n.t('%{assignmentType} %{title}, at %{datetime} until %{endTime}', {
            assignmentType,
            title,
            datetime,
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
        if (this.props.dateStyle === 'todo') {
          return I18n.t('%{assignmentType} %{title} has a to do time at %{datetime}.', {
            assignmentType,
            title,
            datetime,
          })
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
            data-fs-exclude={true}
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
    if (['To Do', 'Calendar Event'].includes(this.props.associated_item)) {
      return (
        <div className={this.style.classNames.title} style={{position: 'relative'}}>
          <Link
            isWithinText={false}
            themeOverride={{
              mediumPaddingHorizontal: '0',
              linkColor: this.props.simplifiedControls ? colors.licorice : undefined,
              linkHoverColor: this.props.simplifiedControls ? colors.licorice : undefined,
            }}
            elementRef={link => {
              this.itemLink = link
            }}
            onClick={
              this.props.associated_item === 'To Do'
                ? this.toDoLinkClick
                : this.openCalendarEventModal
            }
            readOnly={this.props.readOnly}
          >
            <ScreenReaderContent>{this.linkLabel()}</ScreenReaderContent>
            <PresentationContent>{this.props.title}</PresentationContent>
          </Link>
          {this.renderCalendarEventModal()}
        </div>
      )
    }

    return (
      <Link
        href={this.props.html_url}
        isWithinText={false}
        themeOverride={{
          linkColor: this.props.simplifiedControls ? colors.licorice : undefined,
          linkHoverColor: this.props.simplifiedControls ? colors.licorice : undefined,
        }}
        elementRef={link => {
          this.itemLink = link
        }}
        interaction={this.props.readOnly ? 'disabled' : 'enabled'}
      >
        <ScreenReaderContent>{this.linkLabel()}</ScreenReaderContent>
        <PresentationContent>{this.props.title}</PresentationContent>
      </Link>
    )
  }

  renderBadges = () => {
    if (this.props.badges.length) {
      return (
        <BadgeList>
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
    if (this.props.points) {
      return (
        <div className={this.style.classNames.score}>
          <Text size="large">{this.props.points}</Text>
          <Text size="x-small">
            &nbsp;
            {I18n.t('pts')}
          </Text>
        </div>
      )
    }
    if (this.props.associated_item === 'To Do' && !this.props.isObserving) {
      return (
        <div className={this.style.classNames.editButton}>
          <InstUISettingsProvider
            theme={{
              componentOverrides: {
                IconButton: {
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
      this.style.classNames.secondary,
      !this.hasBadges() ? this.style.classNames.secondary_no_badges : ''
    )
    const metricsClasses = classnames(this.style.classNames.metrics, {
      [this.style.classNames.with_end_time]: this.showEndTime(),
    })
    return (
      <div className={secondaryClasses}>
        <div className={this.style.classNames.badges}>{this.renderBadges()}</div>
        <div className={metricsClasses}>
          {this.renderItemSubMetric()}
          <div className={this.style.classNames.due}>
            <Text size="x-small">
              <PresentationContent>{this.renderDateField()}</PresentationContent>
            </Text>
          </div>
        </div>
        {this.props.responsiveSize !== 'small' && this.renderOnlineMeeting()}
      </div>
    )
  }

  renderType = () => {
    if (!this.props.associated_item) {
      return I18n.t('%{course} TO DO', {course: this.props.courseName || ''})
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
        themeOverride={{primaryColor: this.props.color}}
        data-testid="MissingAssignments-CourseName"
      >
        {this.props.courseName}
      </Text>
    )
  }

  renderItemDetails = () => {
    return (
      <div
        className={classnames(
          this.style.classNames.details,
          !this.hasBadges() ? this.style.classNames.details_no_badges : ''
        )}
      >
        {!this.props.simplifiedControls && (
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
    if (this.props.responsiveSize === 'small') {
      return (
        <>
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
          <div className={this.style.classNames.activityIndicator}>
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
          hoverBorderColor: this.props.color,
        }
  }

  renderExtraInfo() {
    const feedback = this.props.feedback
    if (feedback) {
      const comment = feedback.is_media ? I18n.t('You have media feedback.') : feedback.comment
      return (
        <div className={this.style.classNames.feedback}>
          <span className={this.style.classNames.feedbackAvatar}>
            <Avatar
              name={feedback.author_name || '?'}
              src={feedback.author_avatar_url}
              size="small"
              data-fs-exclude={true}
            />
          </span>
          <span className={this.style.classNames.feedbackComment}>
            <Text fontStyle="italic">{comment}</Text>
          </span>
        </div>
      )
    }
    const location = this.props.location
    if (location) {
      return (
        <div className={this.style.classNames.location}>
          <Text>{location}</Text>
        </div>
      )
    }
    return null
  }

  renderCompletedCheckbox() {
    if (this.props.isMissingItem) {
      return (
        <div className={this.style.classNames.completed}>
          <IconWarningLine color="error" />
        </div>
      )
    }

    const assignmentType = this.assignmentType()
    const checkboxLabel = this.state.completed
      ? I18n.t('%{assignmentType} %{title} is marked as done.', {
          assignmentType,
          title: this.props.title,
        })
      : I18n.t('%{assignmentType} %{title} is not marked as done.', {
          assignmentType,
          title: this.props.title,
        })

    return (
      <div className={this.style.classNames.completed}>
        <InstUISettingsProvider
          theme={{
            componentOverrides: {
              CheckboxFacade: this.getCheckboxTheme(),
            },
          }}
        >
          <Checkbox
            ref={this.registerFocusElementRef}
            label={<ScreenReaderContent>{checkboxLabel}</ScreenReaderContent>}
            checked={this.props.toggleAPIPending ? !this.state.completed : this.state.completed}
            onChange={this.props.toggleCompletion}
            disabled={this.props.toggleAPIPending || this.props.isObserving}
            readOnly={this.props.readOnly}
          />
        </InstUISettingsProvider>
      </div>
    )
  }

  renderOnlineMeeting() {
    if (this.props.onlineMeetingURL) {
      const now = moment()
      const enabled =
        (this.props.allDay && now.isSame(this.props.date, 'day')) || // an all day event today
        (this.props.endTime && now.isBetween(this.props.date, this.props.endTime)) || // during an event
        (!this.props.endTime && now.isSame(this.props.date, 'day') && now > this.props.date) // after start time today for an event with no end time
      const srlabel = enabled ? I18n.t('join active online meeting') : I18n.t('join online meeting')
      return (
        <div className={this.style.classNames.onlineMeeting}>
          <Button
            data-testid={enabled ? 'join-button-hot' : 'join-button'}
            size="small"
            color={enabled ? 'success' : 'secondary'}
            margin={this.props.responsiveSize === 'small' ? '0' : '0 0 0 x-small'}
            renderIcon={enabled ? IconVideoCameraSolid : IconVideoCameraLine}
            onClick={() => {
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
        <style>{this.style.css}</style>
        <div
          className={classnames(
            this.style.classNames.root,
            this.style.classNames[this.getLayout()],
            'planner-item',
            {
              [this.style.classNames.missingItem]: this.props.isMissingItem,
            },
            this.props.simplifiedControls ? this.style.classNames.k5Layout : ''
          )}
          ref={this.registerRootDivRef}
        >
          {this.renderNotificationBadge()}
          {this.renderCompletedCheckbox()}
          <div
            className={
              this.props.associated_item === 'To Do'
                ? this.style.classNames.avatar
                : this.style.classNames.icon
            }
            style={{color: this.props.simplifiedControls ? undefined : this.props.color}}
            aria-hidden="true"
          >
            {this.renderIcon()}
          </div>
          <div className={this.style.classNames.layout}>
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

PlannerItem_raw.displayName = 'PlannerItem_raw'

const AnimatablePlannerItem = animatable(PlannerItem_raw)
AnimatablePlannerItem.theme = PlannerItem_raw.theme
export default AnimatablePlannerItem

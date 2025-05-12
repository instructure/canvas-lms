/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import {useScope as createI18nScope} from '@canvas/i18n'

import useDateTimeFormat from '@canvas/use-date-time-format-hook'
import cx from 'classnames'
import {arrayOf, bool, func, string} from 'prop-types'
import React, {Component} from 'react'
import {DragSource, DropTarget} from 'react-dnd'
import {findDOMNode} from 'react-dom'
import {connect} from 'react-redux'
import {bindActionCreators} from 'redux'

import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Badge} from '@instructure/ui-badge'
import {ToggleButton} from '@instructure/ui-buttons'
import {Grid} from '@instructure/ui-grid'
import {Heading} from '@instructure/ui-heading'
import {
  IconAssignmentLine,
  IconBookmarkLine,
  IconBookmarkSolid,
  IconCopySolid,
  IconDragHandleLine,
  IconDuplicateLine,
  IconEditLine,
  IconLockLine,
  IconLtiLine,
  IconPeerReviewLine,
  IconPermissionsLine,
  IconPinLine,
  IconPinSolid,
  IconPublishSolid,
  IconTrashSolid,
  IconUnlockLine,
  IconUnpublishedLine,
  IconUpdownLine,
  IconUserLine,
} from '@instructure/ui-icons'
import {Link} from '@instructure/ui-link'
import {Menu} from '@instructure/ui-menu'
import {Pill} from '@instructure/ui-pill'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

import DiscussionModel from '@canvas/discussions/backbone/models/DiscussionTopic'
import LockIconView from '@canvas/lock-icon'

import CyoeHelper from '@canvas/conditional-release-cyoe-helper'
import masterCourseDataShape from '@canvas/courses/react/proptypes/masterCourseData'
import {isPassedDelayedPostAt} from '@canvas/datetime/react/date-utils'
import select from '@canvas/obj-select'
import UnreadBadge from '@canvas/unread-badge'
import {assignLocation} from '@canvas/util/globalUtils'
import WithBreakpoints, {breakpointsShape} from '@canvas/with-breakpoints'
import {flowRight as compose} from 'lodash'
import moment from 'moment'
import actions from '../actions'
import propTypes from '../propTypes'
import discussionShape from '../proptypes/discussion'
import DiscussionManageMenu from './DiscussionManageMenu'

const I18n = createI18nScope('discussion_row')

const dragTarget = {
  beginDrag(props) {
    return props.discussion
  },
}

const dropTarget = {
  hover(props, monitor, component) {
    const dragIndex = props.getDiscussionPosition(monitor.getItem())
    const hoverIndex = props.getDiscussionPosition(props.discussion)
    if (dragIndex === undefined || hoverIndex === undefined) {
      return
    }
    if (dragIndex === hoverIndex) {
      return
    }
    // eslint-disable-next-line react/no-find-dom-node
    const hoverBoundingRect = findDOMNode(component).getBoundingClientRect()
    const hoverMiddleY = (hoverBoundingRect.bottom - hoverBoundingRect.top) / 2
    const clientOffset = monitor.getClientOffset()
    const hoverClientY = clientOffset.y - hoverBoundingRect.top

    // Only perform the move when the mouse has crossed half of the items height
    // When dragging downwards, only move when the cursor is below 50%
    // When dragging upwards, only move when the cursor is above 50%
    if (dragIndex < hoverIndex && hoverClientY < hoverMiddleY) {
      return
    }
    if (dragIndex > hoverIndex && hoverClientY > hoverMiddleY) {
      return
    }
    props.moveCard(dragIndex, hoverIndex)
  },
}
const REPLY_TO_TOPIC = 'reply_to_topic'
const REPLY_TO_ENTRY = 'reply_to_entry'
class DiscussionRow extends Component {
  static propTypes = {
    canPublish: bool.isRequired,
    canReadAsAdmin: bool.isRequired,
    cleanDiscussionFocus: func.isRequired,
    connectDragSource: func,
    connectDropTarget: func,
    contextType: string.isRequired,
    deleteDiscussion: func.isRequired,
    setCopyTo: func.isRequired,
    setSendTo: func.isRequired,
    discussion: discussionShape.isRequired,
    discussionTopicMenuTools: arrayOf(propTypes.discussionTopicMenuTools),
    displayDeleteMenuItem: bool.isRequired,
    displayDuplicateMenuItem: bool.isRequired,
    displayLockMenuItem: bool.isRequired,
    displayMasteryPathsMenuItem: bool,
    displayMasteryPathsLink: bool,
    displayMasteryPathsPill: bool,
    masteryPathsPillLabel: string, // required if displayMasteryPathsPill is true
    displayManageMenu: bool.isRequired,
    displayPinMenuItem: bool.isRequired,
    displayDifferentiatedModulesTray: bool.isRequired,
    onOpenAssignToTray: func,
    draggable: bool,
    duplicateDiscussion: func.isRequired,
    isDragging: bool,
    isMasterCourse: bool.isRequired,
    masterCourseData: masterCourseDataShape,
    onMoveDiscussion: func,
    toggleSubscriptionState: func.isRequired,
    updateDiscussion: func.isRequired,
    DIRECT_SHARE_ENABLED: bool.isRequired,
    dateFormatter: func.isRequired,
    breakpoints: breakpointsShape.isRequired,
  }

  static defaultProps = {
    connectDragSource(component) {
      return component
    },
    connectDropTarget(component) {
      return component
    },
    discussionTopicMenuTools: [],
    draggable: false,
    isDragging: false,
    masterCourseData: null,
    displayMasteryPathsMenuItem: false,
    displayMasteryPathsLink: false,
    displayMasteryPathsPill: false,
    masteryPathsPillLabel: '',
    onMoveDiscussion: null,
    onOpenAssignToTray: null,
    breakpoints: {},
  }

  componentDidMount = () => {
    this.onFocusManage(this.props)
  }

  UNSAFE_componentWillReceiveProps = nextProps => {
    this.onFocusManage(nextProps)
  }

  // TODO: Move this to a common file so announcements can use this also.
  onFocusManage = props => {
    if (props.discussion.focusOn) {
      switch (props.discussion.focusOn) {
        case 'title':
          this._titleElement.focus()
          break
        case 'manageMenu':
          this._manageMenu.focus()
          break
        case 'toggleButton':
          break
        default:
          throw new Error('Illegal element focus request')
      }
      this.props.cleanDiscussionFocus()
    }
  }

  onManageDiscussion = (e, {action, id, menuTool}) => {
    switch (action) {
      case 'duplicate':
        this.props.duplicateDiscussion(id)
        break
      case 'moveTo':
        this.props.onMoveDiscussion({id, title: this.props.discussion.title})
        break
      case 'togglepinned':
        this.props.updateDiscussion(
          this.props.discussion,
          {pinned: !this.props.discussion.pinned},
          this.makePinSuccessFailMessages(this.props.discussion),
          'manageMenu',
        )
        break
      case 'delete':
        this.props.deleteDiscussion(this.props.discussion)
        break
      case 'togglelocked':
        this.props.updateDiscussion(
          this.props.discussion,
          {locked: !this.props.discussion.locked},
          this.makeLockedSuccessFailMessages(this.props.discussion),
          'manageMenu',
        )
        break
      case 'copyTo':
        this.props.setCopyTo({
          open: true,
          selection: {discussion_topics: [this.props.discussion.id]},
        })
        break
      case 'sendTo':
        this.props.setSendTo({
          open: true,
          selection: {
            content_type: 'discussion_topic',
            content_id: this.props.discussion.id,
          },
        })
        break

      case 'masterypaths':
        window.location = `discussion_topics/${
          this.props.discussion.id
        }/edit?return_to=${encodeURIComponent(window.location.pathname)}#mastery-paths-editor`
        break
      case 'ltiMenuTool':
        window.location = `${menuTool.base_url}&discussion_topics[]=${id}`
        break
      case 'assignTo':
        this.props.onOpenAssignToTray(this.props.discussion)
        break
      case 'edit':
        assignLocation(`${this.props.discussion.html_url}/edit`)
        break
      default:
        throw new Error('Unknown manage discussion action encountered')
    }
  }

  getAccessibleTitle() {
    let result = `${this.props.discussion.title} `
    const availability = this.getAvailabilityString()
    if (availability) result += `${availability} `
    const assignment = this.props.discussion.assignment
    const dueDateString =
      assignment && assignment.due_at
        ? I18n.t('Due %{date} ', {date: this.props.dateFormatter(assignment.due_at)})
        : ' '
    result += dueDateString
    const lastReplyAtDate = this.props.dateFormatter(this.props.discussion.last_reply_at)
    if (lastReplyAtDate.length > 0 && this.props.discussion.discussion_subentry_count > 0) {
      result += I18n.t('Last post at %{date}', {date: lastReplyAtDate})
    }
    return result
  }

  isInaccessibleDueToAnonymity = () => {
    return (
      (this.props.discussion.anonymous_state === 'full_anonymity' ||
        this.props.discussion.anonymous_state === 'partial_anonymity') &&
      !ENV.discussion_anonymity_enabled
    )
  }

  getAvailabilityString = () => {
    if (this.isInaccessibleDueToAnonymity()) {
      return (
        <Text size="small">
          {this.props.canReadAsAdmin
            ? [
                I18n.t('Enable '),
                <Link href={ENV.FEATURE_FLAGS_URL} key={this.props.discussion.id} target="_blank">
                  {I18n.t('Discussions/Announcements Redesign')}
                </Link>,
                I18n.t(' to view anonymous discussion'),
              ]
            : I18n.t('Unavailable')}
        </Text>
      )
    }
    const assignment = this.props.discussion.assignment

    const ungradedLockAt = this.props.discussion.ungraded_discussion_overrides?.sort((a, b) =>
      moment.utc(b.assignment_override?.lock_at).diff(moment.utc(a.assignment_override?.lock_at)),
    )

    const ungradedUnlockAt = this.props.discussion.ungraded_discussion_overrides?.sort((a, b) =>
      moment
        .utc(b.assignment_override?.unlock_at)
        .diff(moment.utc(a.assignment_override?.unlock_at)),
    )

    let availabilityBegin, availabilityEnd

    if (assignment) {
      availabilityBegin = assignment.unlock_at
    } else if (ungradedUnlockAt?.length > 0) {
      availabilityBegin = ungradedUnlockAt?.[0]?.assignment_override.unlock_at
    } else {
      availabilityBegin = this.props.discussion.delayed_post_at
    }

    if (assignment) {
      availabilityEnd = assignment.lock_at
    } else if (ungradedLockAt?.length > 0) {
      availabilityEnd = ungradedLockAt?.[0]?.assignment_override.lock_at
    } else {
      availabilityEnd = this.props.discussion.lock_at
    }

    if (
      availabilityBegin &&
      !isPassedDelayedPostAt({checkDate: null, delayedDate: availabilityBegin})
    ) {
      return I18n.t('Not available until %{date}', {
        date: this.props.dateFormatter(availabilityBegin),
      })
    }
    if (availabilityEnd) {
      if (isPassedDelayedPostAt({checkDate: null, delayedDate: availabilityEnd})) {
        return I18n.t('No longer available')
      } else {
        return I18n.t('Available until %{date}', {date: this.props.dateFormatter(availabilityEnd)})
      }
    }
    return ''
  }

  makePinSuccessFailMessages = () => {
    const successMessage = this.props.discussion.pinned
      ? I18n.t('Unpin of discussion %{title} succeeded', {title: this.props.discussion.title})
      : I18n.t('Pin of discussion %{title} succeeded', {title: this.props.discussion.title})
    const failMessage = this.props.discussion.pinned
      ? I18n.t('Unpin of discussion %{title} failed', {title: this.props.discussion.title})
      : I18n.t('Pin of discussion %{title} failed', {title: this.props.discussion.title})
    return {successMessage, failMessage}
  }

  makeLockedSuccessFailMessages = () => {
    const successMessage = this.props.discussion.locked
      ? I18n.t('Unlock discussion %{title} succeeded', {title: this.props.discussion.title})
      : I18n.t('Lock discussion %{title} succeeded', {title: this.props.discussion.title})
    const failMessage = this.props.discussion.locked
      ? I18n.t('Unlock discussion %{title} failed', {title: this.props.discussion.title})
      : I18n.t('Lock discussion %{title} failed', {title: this.props.discussion.title})
    return {successMessage, failMessage}
  }

  readCount = () => {
    const readCount =
      this.props.discussion.discussion_subentry_count > 0 &&
      !this.isInaccessibleDueToAnonymity() ? (
        <UnreadBadge
          key={`Badge_${this.props.discussion.id}`}
          unreadCount={this.props.discussion.unread_count}
          unreadLabel={I18n.t('%{count} unread replies', {
            count: this.props.discussion.unread_count,
          })}
          totalCount={this.props.discussion.discussion_subentry_count}
          totalLabel={I18n.t('%{count} replies', {
            count: this.props.discussion.discussion_subentry_count,
          })}
        />
      ) : null
    return readCount
  }

  initializeMasterCourseIcon = container => {
    const masterCourse = {
      courseData: this.props.masterCourseData || {},
      getLockOptions: () => ({
        model: new DiscussionModel(this.props.discussion),
        unlockedText: I18n.t('%{title} is unlocked. Click to lock.', {
          title: this.props.discussion.title,
        }),
        lockedText: I18n.t('%{title} is locked. Click to unlock', {
          title: this.props.discussion.title,
        }),
        course_id: this.props.masterCourseData.masterCourse.id,
        content_id: this.props.discussion.id,
        content_type: 'discussion_topic',
      }),
    }
    const {courseData = {}, getLockOptions} = masterCourse || {}
    if (container && (courseData.isMasterCourse || courseData.isChildCourse)) {
      this.unmountMasterCourseLock()
      const opts = getLockOptions()

      // initialize master course lock icon, which is a Backbone view
      // I know, I know, backbone in react is grosssss but wachagunnado
      this.masterCourseLock = new LockIconView({...opts, el: container})
      this.masterCourseLock.render()
    }
  }

  subscribeButton = () =>
    !this.isInaccessibleDueToAnonymity() && (
      <span
        className="subscribe-button"
        key={`Subscribe_${this.props.discussion.id}`}
        data-testid="discussion-subscribe"
        data-action-state={
          this.props.discussion.subscribed ? 'unsubscribeButton' : 'subscribeButton'
        }
      >
        <ToggleButton
          size="small"
          status={this.props.discussion.subscribed ? 'pressed' : 'unpressed'}
          color={this.props.discussion.subscribed ? 'success' : 'secondary'}
          renderIcon={
            this.props.discussion.subscribed ? <IconBookmarkSolid /> : <IconBookmarkLine />
          }
          renderTooltipContent={
            this.props.discussion.subscribed
              ? I18n.t('Unsubscribe from %{title}', {
                  title: this.props.discussion.title,
                })
              : this.props.discussion.subscription_hold !== undefined
                ? I18n.t('Reply to subscribe')
                : I18n.t('Subscribe to %{title}', {title: this.props.discussion.title})
          }
          screenReaderLabel={
            this.props.discussion.subscribed
              ? I18n.t('Subscribed')
              : this.props.discussion.subscription_hold !== undefined
                ? I18n.t('Reply to subscribe')
                : I18n.t('Unsubscribed')
          }
          interaction={
            this.props.discussion.subscription_hold !== undefined ? 'disabled' : 'enabled'
          }
          onClick={() => this.props.toggleSubscriptionState(this.props.discussion)}
        />
      </span>
    )

  publishButton = () =>
    this.props.canPublish && !this.isInaccessibleDueToAnonymity() ? (
      <span
        className="publish-button"
        key={`Publish_${this.props.discussion.id}`}
        data-testid="discussion-publish"
        data-action-state={this.props.discussion.published ? 'unpublishButton' : 'publishButton'}
      >
        <ToggleButton
          size="small"
          status={this.props.discussion.published ? 'pressed' : 'unpressed'}
          color={this.props.discussion.published ? 'success' : 'secondary'}
          renderIcon={
            this.props.discussion.published ? <IconPublishSolid /> : <IconUnpublishedLine />
          }
          renderTooltipContent={
            this.props.discussion.published
              ? I18n.t('Unpublish %{title}', {title: this.props.discussion.title})
              : I18n.t('Publish %{title}', {title: this.props.discussion.title})
          }
          screenReaderLabel={
            this.props.discussion.published
              ? I18n.t('Unpublish %{title}', {
                  title: this.props.discussion.title,
                })
              : I18n.t('Publish %{title}', {
                  title: this.props.discussion.title,
                })
          }
          interaction={
            !this.props.discussion.can_unpublish && this.props.discussion.published
              ? 'disabled'
              : 'enabled'
          }
          onClick={() =>
            this.props.updateDiscussion(
              this.props.discussion,
              {
                published: !this.props.discussion.published,
              },
              {},
            )
          }
        />
      </span>
    ) : null

  pinMenuItemDisplay = () => {
    if (this.props.discussion.pinned) {
      return (
        <span aria-hidden="true">
          <IconPinLine />
          &nbsp;&nbsp;{I18n.t('Unpin')}
        </span>
      )
    } else {
      return (
        <span aria-hidden="true">
          <IconPinSolid />
          &nbsp;&nbsp;{I18n.t('Pin')}
        </span>
      )
    }
  }

  unmountMasterCourseLock = () => {
    if (this.masterCourseLock) {
      this.masterCourseLock.remove()
      this.masterCourseLock = null
    }
  }

  createMenuItem = (itemKey, visibleItemLabel, screenReaderContent, dataActionState) => (
    <Menu.Item
      key={itemKey}
      value={{action: itemKey, id: this.props.discussion.id}}
      id={`${itemKey}-discussion-menu-option`}
      data-action-state={dataActionState}
    >
      {visibleItemLabel}
      <ScreenReaderContent>{screenReaderContent}</ScreenReaderContent>
    </Menu.Item>
  )

  renderMenuToolIcon(menuTool) {
    if (menuTool.canvas_icon_class) {
      return (
        <span>
          <i className={menuTool.canvas_icon_class} />
          &nbsp;&nbsp;{menuTool.title}
        </span>
      )
    } else if (menuTool.icon_url) {
      return (
        <span>
          <img alt={menuTool.title} className="icon lti_tool_icon" src={menuTool.icon_url} />
          &nbsp;&nbsp;{menuTool.title}
        </span>
      )
    } else {
      return (
        <span>
          <IconLtiLine />
          &nbsp;&nbsp;{menuTool.title}
        </span>
      )
    }
  }

  renderMenuList = () => {
    const discussionTitle = this.props.discussion.title
    const menuList = []

    if (this.props.discussion?.permissions?.update && this.props.discussion?.html_url) {
      menuList.push(
        this.createMenuItem(
          'edit',
          <span aria-hidden="true">
            <IconEditLine />
            &nbsp;&nbsp;{I18n.t('Edit')}
          </span>,
          I18n.t('Edit discussion %{title}', {title: discussionTitle}),
        ),
      )
    }

    if (this.props.displayLockMenuItem) {
      const menuLabel = this.props.discussion.locked
        ? I18n.t('Open for comments')
        : I18n.t('Close for comments')
      const screenReaderContent = this.props.discussion.locked
        ? I18n.t('Open discussion %{title} for comments', {title: discussionTitle})
        : I18n.t('Close discussion %{title} for comments', {title: discussionTitle})
      const icon = this.props.discussion.locked ? <IconUnlockLine /> : <IconLockLine />
      menuList.push(
        this.createMenuItem(
          'togglelocked',
          <span aria-hidden="true">
            {' '}
            {icon}&nbsp;&nbsp;{menuLabel}{' '}
          </span>,
          screenReaderContent,
          this.props.discussion.locked ? 'unlockButton' : 'lockButton',
        ),
      )
    }

    const showAssignTo =
      this.props.discussion.assignment_id ||
      (!this.props.discussion.assignment_id && !this.props.discussion.group_category_id)
    if (this.props.displayDifferentiatedModulesTray && showAssignTo) {
      menuList.push(
        this.createMenuItem(
          'assignTo',
          <span aria-hidden="true">
            <IconPermissionsLine />
            &nbsp;&nbsp;{I18n.t('Assign To...')}
          </span>,
          I18n.t('Set Assign to for %{title}', {title: discussionTitle}),
        ),
      )
    }

    if (this.props.displayPinMenuItem) {
      const screenReaderContent = this.props.discussion.pinned
        ? I18n.t('Unpin discussion %{title}', {title: discussionTitle})
        : I18n.t('Pin discussion %{title}', {title: discussionTitle})
      menuList.push(
        this.createMenuItem(
          'togglepinned',
          this.pinMenuItemDisplay(),
          screenReaderContent,
          this.props.discussion.pinned ? 'unpinButton' : 'pinButton',
        ),
      )
    }

    if (
      ENV.show_additional_speed_grader_links &&
      this.props.discussion.assignment &&
      this.props.discussion.published
    ) {
      const assignmentId = this.props.discussion.assignment.id
      menuList.push(
        this.createMenuItem(
          'speed-grader-link',
          <a
            href={`gradebook/speed_grader?assignment_id=${assignmentId}`}
            className="icon-speed-grader"
            style={{color: 'inherit', textDecoration: 'none'}}
          >
            {I18n.t('SpeedGrader')}
          </a>,
          I18n.t('Navigate to SpeedGrader for %{title} assignment', {title: discussionTitle}),
        ),
      )
    }

    if (this.props.onMoveDiscussion && !this.isInaccessibleDueToAnonymity()) {
      menuList.push(
        this.createMenuItem(
          'moveTo',
          <span aria-hidden="true">
            <IconUpdownLine />
            &nbsp;&nbsp;{I18n.t('Move To')}
          </span>,
          I18n.t('Move discussion %{title}', {title: discussionTitle}),
        ),
      )
    }

    if (this.props.displayDuplicateMenuItem && !this.isInaccessibleDueToAnonymity()) {
      menuList.push(
        this.createMenuItem(
          'duplicate',
          <span aria-hidden="true">
            <IconCopySolid />
            &nbsp;&nbsp;{I18n.t('Duplicate')}
          </span>,
          I18n.t('Duplicate discussion %{title}', {title: discussionTitle}),
        ),
      )
    }

    if (this.props.DIRECT_SHARE_ENABLED && !this.isInaccessibleDueToAnonymity()) {
      menuList.push(
        this.createMenuItem(
          'sendTo',
          <span aria-hidden="true">
            <IconUserLine />
            &nbsp;&nbsp;{I18n.t('Send To...')}
          </span>,
          I18n.t('Send %{title} to user', {title: discussionTitle}),
        ),
      )
      menuList.push(
        this.createMenuItem(
          'copyTo',
          <span aria-hidden="true">
            <IconDuplicateLine />
            &nbsp;&nbsp;{I18n.t('Copy To...')}
          </span>,
          I18n.t('Copy %{title} to course', {title: discussionTitle}),
        ),
      )
    }

    // This returns an empty struct if assignment_id is falsey
    if (this.props.displayMasteryPathsMenuItem && !this.isInaccessibleDueToAnonymity()) {
      menuList.push(
        this.createMenuItem(
          'masterypaths',
          <span aria-hidden="true">{I18n.t('Mastery Paths')}</span>,
          I18n.t('Edit Mastery Paths for %{title}', {title: discussionTitle}),
        ),
      )
    }

    if (this.props.discussionTopicMenuTools.length > 0 && !this.isInaccessibleDueToAnonymity()) {
      this.props.discussionTopicMenuTools.forEach(menuTool => {
        menuList.push(
          <Menu.Item
            key={menuTool.base_url}
            value={{
              action: 'ltiMenuTool',
              id: this.props.discussion.id,
              title: this.props.discussion.title,
              menuTool,
            }}
            id="menuTool-discussion-menu-option"
          >
            <span aria-hidden="true">{this.renderMenuToolIcon(menuTool)}</span>
            <ScreenReaderContent>{menuTool.title}</ScreenReaderContent>
          </Menu.Item>,
        )
      })
    }

    if (this.props.displayDeleteMenuItem) {
      menuList.push(
        this.createMenuItem(
          'delete',
          <span aria-hidden="true">
            <IconTrashSolid />
            &nbsp;&nbsp;{I18n.t('Delete')}
          </span>,
          I18n.t('Delete discussion %{title}', {title: discussionTitle}),
        ),
      )
    }

    return menuList
  }

  renderDragHandleIfAppropriate = () => {
    if (this.props.draggable && this.props.connectDragSource) {
      return (
        <div className="ic-item-row__drag-col" data-testid="ic-drag-handle-icon-container">
          <span>
            <Text color="secondary" size="large">
              <IconDragHandleLine />
            </Text>
          </span>
        </div>
      )
    } else {
      return null
    }
  }

  renderTitle = () => {
    const refFn = c => {
      this._titleElement = c
    }
    const linkUrl = this.props.discussion.html_url
    return (
      <Heading as="h3" level="h4" margin="0">
        {this.isInaccessibleDueToAnonymity() ? (
          <>
            <Text color="secondary" data-testid={`discussion-title-${this.props.discussion.id}`}>
              <span aria-hidden="true">{this.props.discussion.title}</span>
            </Text>
            <ScreenReaderContent>{this.getAccessibleTitle()}</ScreenReaderContent>
          </>
        ) : (
          <Link
            href={linkUrl}
            ref={refFn}
            data-testid={`discussion-link-${this.props.discussion.id}`}
            isWithinText={false}
            themeOverride={{
              fontWeight: 700,
            }}
          >
            {this.props.discussion.read_state !== 'read' && (
              <ScreenReaderContent>{I18n.t('unread,')}</ScreenReaderContent>
            )}
            <span aria-hidden="true">{this.props.discussion.title}</span>
            <ScreenReaderContent>{this.getAccessibleTitle()}</ScreenReaderContent>
          </Link>
        )}
      </Heading>
    )
  }

  renderLastReplyAt = size => {
    const datetimeString = this.props.dateFormatter(this.props.discussion.last_reply_at)
    if (!datetimeString.length || this.props.discussion.discussion_subentry_count === 0) {
      return null
    }
    return (
      <span className="ic-discussion-row__content last-reply-at">
        <Text color={this.isInaccessibleDueToAnonymity() ? 'secondary' : null} size={size}>
          {I18n.t('Last post at %{date}', {date: datetimeString})}
        </Text>
      </span>
    )
  }

  renderDueDate = size => {
    const assignment = this.props.discussion.assignment
    let dueDateString = null
    let className = ''
    if (assignment && assignment.due_at) {
      className = 'due-date'
      dueDateString = I18n.t('Due %{date}', {date: this.props.dateFormatter(assignment.due_at)})
    } else if (this.props.discussion.todo_date) {
      className = 'todo-date'
      dueDateString = I18n.t('To do %{date}', {
        date: this.props.dateFormatter(this.props.discussion.todo_date),
      })
    }
    return (
      dueDateString && (
        <span className={`ic-discussion-row__content ${className}`}>
          <Text size={size}>{dueDateString}</Text>
        </span>
      )
    )
  }

  renderAvailabilityDate = size => {
    // Check if we are too early for the topic to be available
    const availabilityString = this.getAvailabilityString()
    return (
      availabilityString && (
        <span className="discussion-availability ic-discussion-row__content">
          <Text size={size}>{this.getAvailabilityString()}</Text>
        </span>
      )
    )
  }

  renderCheckpointInfo = (size, timestampStyleOverride) => {
    const {assignment} = this.props.discussion
    if (
      !assignment ||
      !Array.isArray(assignment.checkpoints) ||
      assignment.checkpoints.length === 0
    ) {
      return null
    }

    const replyToTopicCheckpoint = assignment.checkpoints.find(e => e.tag === REPLY_TO_TOPIC)
    const replyToEntryCheckpoint = assignment.checkpoints.find(e => e.tag === REPLY_TO_ENTRY)

    if (
      (replyToTopicCheckpoint && !replyToEntryCheckpoint) ||
      (!replyToTopicCheckpoint && replyToEntryCheckpoint)
    ) {
      console.error(
        I18n.t(
          'Error: Inconsistent checkpoints - Only one of the reply-to-topic or reply-to-entry checkpoint exists.',
        ),
      )
    }

    const replyToTopic = replyToTopicCheckpoint ? replyToTopicCheckpoint.due_at : null
    const replyToEntry = replyToEntryCheckpoint ? replyToEntryCheckpoint.due_at : null
    const noDate = I18n.t('No Due Date')

    const dueDateString = I18n.t(
      ' Reply to topic: %{topicDate}  Required replies (%{count}): %{entryDate}',
      {
        topicDate: replyToTopic ? this.props.dateFormatter(replyToTopic) : noDate,
        entryDate: replyToEntry ? this.props.dateFormatter(replyToEntry) : noDate,
        count: this.props.discussion.reply_to_entry_required_count,
      },
    )

    return (
      dueDateString && (
        <Grid.Row>
          <Grid.Col textAlign="end">
            <span aria-hidden="true" style={timestampStyleOverride}>
              <span className="ic-discussion-row__content due-date">
                <Text size={size}>{dueDateString}</Text>
              </span>
            </span>
          </Grid.Col>
        </Grid.Row>
      )
    )
  }

  renderIcon = () => {
    const accessibleGradedIcon = (isSuccessColor = true) => (
      <Text
        color={isSuccessColor ? 'success' : 'secondary'}
        size={this.props.breakpoints.mobileOnly ? 'medium' : 'large'}
      >
        <IconAssignmentLine title={I18n.t('Graded Discussion')} />
      </Text>
    )
    if (this.props.discussion.assignment) {
      return accessibleGradedIcon(!!this.props.discussion.published)
    }
    return null
  }

  renderUpperRightBadges = () => {
    const assignment = this.props.discussion.assignment
    const peerReview = assignment ? assignment.peer_reviews : false
    const maybeRenderPeerReviewIcon = peerReview ? (
      <span className="ic-item-row__peer_review">
        <Text color="success" size="medium">
          <IconPeerReviewLine />
        </Text>
      </span>
    ) : null
    const maybeDisplayManageMenu = this.props.displayManageMenu ? (
      <span display="inline-block" className={this.props.breakpoints.mobileOnly ? 'mobile' : ''}>
        <DiscussionManageMenu
          menuRefFn={c => {
            this._manageMenu = c
          }}
          onSelect={this.onManageDiscussion}
          entityTitle={this.props.discussion.title}
          menuOptions={this.renderMenuList}
        />
      </span>
    ) : null
    const returnTo = encodeURIComponent(window.location.pathname)
    const discussionId = this.props.discussion.id
    const maybeRenderMasteryPathsPill = this.props.displayMasteryPathsPill ? (
      <span display="inline-block" className="discussion-row-mastery-paths-pill">
        <Pill>{this.props.masteryPathsPillLabel}</Pill>
      </span>
    ) : null
    const maybeRenderMasteryPathsLink = this.props.displayMasteryPathsLink ? (
      <a
        href={`discussion_topics/${discussionId}/edit?return_to=${returnTo}#mastery-paths-editor`}
        className="discussion-index-mastery-paths-link"
      >
        {I18n.t('Mastery Paths')}
      </a>
    ) : null
    const actionsContent = [this.publishButton(), this.subscribeButton()]
    const style = {
      display: 'flex',
      justifyContent: this.props.breakpoints.mobileOnly ? 'space-between' : 'end',
      padding: this.props.breakpoints.mobileOnly ? '1em 0' : '0',
    }
    return (
      <div style={style}>
        <div
          className={'ic-button-line-left ' + (this.props.breakpoints.mobileOnly ? 'mobile' : '')}
        >
          {this.props.breakpoints.mobileOnly && this.renderIcon()}
          {maybeRenderMasteryPathsPill}
          {maybeRenderMasteryPathsLink}
          {maybeRenderPeerReviewIcon}
          {this.readCount()}
        </div>
        <div
          className={'ic-button-line-right ' + (this.props.breakpoints.mobileOnly ? 'mobile' : '')}
        >
          {actionsContent}
          {this.props.masterCourseData && (
            <span
              ref={this.initializeMasterCourseIcon}
              data-testid="ic-master-course-icon-container"
              className="ic-item-row__master-course-lock"
            />
          )}
          {maybeDisplayManageMenu}
        </div>
      </div>
    )
  }

  renderDiscussion = () => {
    const classes = cx({
      'ic-item-row': true,
      'ic-discussion-row': true,
      mobile: this.props.breakpoints.mobileOnly,
    })
    const timestampStyleOverride = {
      textAlign: this.props.breakpoints.mobileOnly ? 'end' : '',
      width: this.props.breakpoints.mobileOnly ? '100%' : '',
      display: this.props.breakpoints.mobileOnly ? 'inline-block' : '',
    }
    const timestampTextSize = this.props.breakpoints.mobileOnly ? 'small' : 'medium'
    return this.props.connectDropTarget(
      this.props.connectDragSource(
        <div
          style={{
            opacity: this.props.isDragging ? 0 : 1,
          }}
          className={`${classes}`}
        >
          <div className="ic-discussion-row-container">
            {this.props.breakpoints.mobileOnly && this.renderBlueUnreadBadge()}
            <span className="ic-drag-handle-container">{this.renderDragHandleIfAppropriate()}</span>
            {!this.props.breakpoints.mobileOnly && this.renderIcon()}
            <span
              className="ic-discussion-content-container"
              style={{
                marginLeft: this.props.breakpoints.mobileOnly ? '16px' : 0,
              }}
            >
              <Grid startAt="medium" vAlign="middle" rowSpacing="none" colSpacing="none">
                <Grid.Row vAlign="middle">
                  <Grid.Col vAlign="middle" textAlign="start">
                    {this.renderTitle()}
                  </Grid.Col>
                  <Grid.Col vAlign="top" textAlign="end">
                    {this.renderUpperRightBadges()}
                  </Grid.Col>
                </Grid.Row>
                <Grid.Row>
                  <Grid.Col textAlign="start">
                    <span
                      aria-hidden="true"
                      style={this.renderLastReplyAt() ? timestampStyleOverride : {}}
                    >
                      {this.renderLastReplyAt(timestampTextSize)}
                    </span>
                  </Grid.Col>
                  <Grid.Col textAlign="center">
                    <span
                      aria-hidden="true"
                      style={this.renderAvailabilityDate() ? timestampStyleOverride : {}}
                    >
                      {this.renderAvailabilityDate(timestampTextSize)}
                    </span>
                  </Grid.Col>
                  <Grid.Col textAlign="end">
                    <span
                      aria-hidden="true"
                      style={this.renderDueDate() ? timestampStyleOverride : {}}
                    >
                      {this.renderDueDate(timestampTextSize)}
                    </span>
                  </Grid.Col>
                </Grid.Row>
                {this.renderCheckpointInfo(timestampTextSize, timestampStyleOverride)}
              </Grid>
            </span>
          </div>
        </div>,
        {dropEffect: 'copy'},
      ),
    )
  }

  renderBlueUnreadBadge() {
    const mobileTheme = {
      top: this.props.breakpoints.mobileOnly ? '19px' : 0,
      position: this.props.breakpoints.mobileOnly ? 'absolute' : 'relative',
      marginLeft: this.props.breakpoints.mobileOnly && this.props.draggable ? '11px' : '0px',
    }
    if (this.props.discussion.read_state !== 'read') {
      return (
        <div data-testid="ic-blue-unread-badge" style={mobileTheme}>
          <Badge margin="0 small x-small 0" standalone={true} type="notification" />
        </div>
      )
    } else if (!this.props.breakpoints.mobileOnly) {
      return (
        <View display="block" margin="0 small x-small 0">
          <View display="block" margin="0 small x-small 0" />
        </View>
      )
    }
  }

  render() {
    return (
      <div>
        <Grid startAt="medium" vAlign="middle" colSpacing="none">
          <Grid.Row>
            {/* discussion topics is different for badges so we use our own read indicator instead of passing to isRead */}
            <Grid.Col width="auto">
              {!this.props.breakpoints.mobileOnly && this.renderBlueUnreadBadge()}
            </Grid.Col>
            <Grid.Col>{this.renderDiscussion()}</Grid.Col>
          </Grid.Row>
        </Grid>
      </div>
    )
  }
}

const mapDispatch = dispatch => {
  const actionKeys = [
    'cleanDiscussionFocus',
    'duplicateDiscussion',
    'toggleSubscriptionState',
    'updateDiscussion',
    'setCopyTo',
    'setSendTo',
  ]
  return bindActionCreators(select(actions, actionKeys), dispatch)
}

const mapState = (state, ownProps) => {
  const {discussion} = ownProps
  const cyoe = CyoeHelper.getItemData(discussion.assignment_id)
  let masterCourse = true
  if (!state.masterCourseData || !state.masterCourseData.isMasterCourse) {
    masterCourse = false
  }
  const shouldShowMasteryPathsPill =
    cyoe.isReleased &&
    cyoe.releasedLabel &&
    cyoe.releasedLabel !== '' &&
    discussion.permissions.update
  const propsFromState = {
    canPublish: state.permissions.publish,
    canReadAsAdmin: state.permissions.read_as_admin,
    contextType: state.contextType,
    discussionTopicMenuTools: state.discussionTopicMenuTools,
    displayDeleteMenuItem:
      !(discussion.is_master_course_child_content && discussion.restricted_by_master_course) &&
      discussion.permissions.delete,
    displayDuplicateMenuItem: state.permissions.manage_content,
    displayLockMenuItem: discussion.can_lock && discussion.permissions.update,
    displayMasteryPathsMenuItem: cyoe.isCyoeAble,
    displayMasteryPathsLink: cyoe.isTrigger && discussion.permissions.update,
    displayMasteryPathsPill: shouldShowMasteryPathsPill,
    masteryPathsPillLabel: cyoe.releasedLabel,
    displayManageMenu:
      discussion.permissions.delete ||
      (state.DIRECT_SHARE_ENABLED && state.permissions.read_as_admin),
    displayPinMenuItem: state.permissions.moderate,
    displayDifferentiatedModulesTray:
      discussion.permissions.manage_assign_to && state.contextType === 'course',
    masterCourseData: state.masterCourseData,
    isMasterCourse: masterCourse,
    DIRECT_SHARE_ENABLED: state.DIRECT_SHARE_ENABLED,
  }
  return {...ownProps, ...propsFromState}
}

// The main component is a class component, so to use a React hook
// we have to use a HOC to wrap it in a function component.
function withDateFormatHook(Original) {
  function WrappedComponent(props) {
    const dateFormatter = useDateTimeFormat('time.formats.short')
    return <Original {...props} dateFormatter={dateFormatter} />
  }
  const displayName = Original.displayName || Original.name
  WrappedComponent.displayName = `WithDateFormat(${displayName})`
  return WrappedComponent
}

const WrappedDiscussionRow = WithBreakpoints(withDateFormatHook(DiscussionRow))

export const DraggableDiscussionRow = compose(
  DropTarget('Discussion', dropTarget, dConnect => ({
    connectDropTarget: dConnect.dropTarget(),
  })),
  DragSource('Discussion', dragTarget, (dConnect, monitor) => ({
    connectDragSource: dConnect.dragSource(),
    isDragging: monitor.isDragging(),
    connectDragPreview: dConnect.dragPreview(),
  })),
)(WrappedDiscussionRow)

export {DiscussionRow} // for tests only

export const ConnectedDiscussionRow = connect(mapState, mapDispatch)(WrappedDiscussionRow)
export const ConnectedDraggableDiscussionRow = connect(
  mapState,
  mapDispatch,
)(DraggableDiscussionRow)

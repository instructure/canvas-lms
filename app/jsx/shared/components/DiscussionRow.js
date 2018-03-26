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

import I18n from 'i18n!discussion_row'
import React, { Component } from 'react'
import { func, bool } from 'prop-types'
import $ from 'jquery'
import 'jquery.instructure_date_and_time'

import { DragSource, DropTarget } from 'react-dnd';
import { findDOMNode } from 'react-dom'
import Container from '@instructure/ui-core/lib/components/Container'
import Badge from '@instructure/ui-core/lib/components/Badge'
import Text from '@instructure/ui-core/lib/components/Text'
import Grid, { GridCol, GridRow} from '@instructure/ui-core/lib/components/Grid'
import { MenuItem } from '@instructure/ui-core/lib/components/Menu'
import ScreenReaderContent from '@instructure/ui-core/lib/components/ScreenReaderContent'
import IconTimer from 'instructure-icons/lib/Line/IconTimerLine'
import IconAssignmentLine from 'instructure-icons/lib/Line/IconAssignmentLine'
import IconRssLine from 'instructure-icons/lib/Line/IconRssLine'
import IconRssSolid from 'instructure-icons/lib/Solid/IconRssSolid'
import IconPublishSolid from 'instructure-icons/lib/Solid/IconPublishSolid'
import IconCopySolid from 'instructure-icons/lib/Solid/IconCopySolid'
import IconUpdownLine from 'instructure-icons/lib/Line/IconUpdownLine'
import IconTrashSolid from 'instructure-icons/lib/Solid/IconTrashSolid'
import IconPinSolid from 'instructure-icons/lib/Solid/IconPinSolid'
import IconPinLine from 'instructure-icons/lib/Line/IconPinLine'
import IconReply from 'instructure-icons/lib/Line/IconReplyLine'
import IconUnpublishedLine from 'instructure-icons/lib/Line/IconUnpublishedLine'

import DiscussionModel from 'compiled/models/DiscussionTopic'
import compose from '../helpers/compose'
import SectionsTooltip from '../SectionsTooltip'
import CourseItemRow from './CourseItemRow'
import UnreadBadge from './UnreadBadge'

import ToggleIcon from './ToggleIcon'
import discussionShape from '../proptypes/discussion'
import masterCourseDataShape from '../proptypes/masterCourseData'

function makeTimestamp ({ delayed_post_at, posted_at }) {
  return delayed_post_at
  ? {
      title: (
        <span>
          <Container margin="0 x-small">
            <Text color="secondary"><IconTimer /></Text>
          </Container>
          {I18n.t('Delayed until:')}
        </span>
      ),
      date: delayed_post_at
  }
  : { title: I18n.t('Posted on:'), date: posted_at }
}
const discussionTarget = {
  beginDrag (props) {
    return props.discussion
  },
}

const otherTarget = {
  hover(props, monitor, component) {
    const dragIndex = monitor.getItem().sortableId
    const hoverIndex = props.discussion.sortableId
    if (dragIndex === undefined || hoverIndex === undefined) {
      return
    }
    if (dragIndex === hoverIndex) {
      return
    }
    const hoverBoundingRect = findDOMNode(component).getBoundingClientRect() // eslint-disable-line
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
    monitor.getItem().sortableId = hoverIndex // eslint-disable-line
  },
}

export default class DiscussionRow extends Component {
  static propTypes = {
    discussion: discussionShape.isRequired,
    masterCourseData: masterCourseDataShape,
    rowRef: func,
    moveCard: func, // eslint-disable-line
    deleteDiscussion: func.isRequired,
    onSelectedChanged: func,
    connectDragSource: func,
    connectDragPreview: func,
    connectDropTarget: func,
    isDragging: bool,
    draggable: bool,
    onToggleSubscribe: func.isRequired,
    displayManageMenu: bool.isRequired,
    displayPinMenuItem: bool.isRequired,
    displayDuplicateMenuItem: bool.isRequired,
    displayDeleteMenuItem: bool.isRequired,
    displayLockMenuItem: bool.isRequired,
    displayMasteryPathsMenuItem: bool.isRequired,
    duplicateDiscussion: func.isRequired,
    cleanDiscussionFocus: func.isRequired,
    updateDiscussion: func.isRequired,
    canPublish: bool.isRequired,
    onMoveDiscussion: func,
  }

  static defaultProps = {
    connectDragPreview (component) {return component},
    connectDragSource (component) {return component},
    connectDropTarget (component) {return component},
    draggable: false,
    isDragging: false,
    masterCourseData: null,
    moveCard: () => {},
    onMoveDiscussion: null,
    onSelectedChanged () {},
    rowRef () {},
  }

  onManageDiscussion = (e, { action, id }) => {
    switch (action) {
     case 'duplicate':
       this.props.duplicateDiscussion(id)
       break
     case 'moveTo':
       this.props.onMoveDiscussion({ id, title: this.props.discussion.title })
       break
     case 'togglepinned':
       this.props.updateDiscussion(this.props.discussion, { pinned: !this.props.discussion.pinned },
         this.makePinSuccessFailMessages(this.props.discussion), 'manageMenu')
       break
     case 'delete':
       this.props.deleteDiscussion(this.props.discussion)
       break
     case 'togglelocked':
       this.props.updateDiscussion(this.props.discussion, { locked: !this.props.discussion.locked },
         this.makePinSuccessFailMessages(this.props.discussion), 'manageMenu')
       break
     case 'masterypaths':
       // This is terrible
       const returnTo = encodeURIComponent(window.location.pathname)
       window.location =
         `discussion_topics/${this.props.discussion.id}/edit?return_to=${returnTo}#mastery-paths-editor`
       break
     default:
       throw new Error(I18n.t('Unknown manage discussion action encountered'))
    }
  }

  makePinSuccessFailMessages = () => {
    const successMessage = this.props.discussion.pinned ?
      I18n.t('Unpin of discussion %{title} succeeded', { title: this.props.discussion.title }) :
      I18n.t('Pin of discussion %{title} succeeded', { title: this.props.discussion.title })
    const failMessage = this.props.discussion.pinned ?
      I18n.t('Unpin of discussion %{title} failed', { title: this.props.discussion.title }) :
      I18n.t('Pin of discussion %{title} failed', { title: this.props.discussion.title })
    return { successMessage, failMessage }
  }

  readCount = () => {
  const readCount = this.props.discussion.discussion_subentry_count > 0
    ? (
      <UnreadBadge
        unreadCount={this.props.discussion.unread_count}
        unreadLabel={I18n.t('%{count} unread replies', { count: this.props.discussion.unread_count })}
        totalCount={this.props.discussion.discussion_subentry_count}
        totalLabel={I18n.t('%{count} replies', { count: this.props.discussion.discussion_subentry_count })}
      />
    )
    : null
    return readCount
  }

  subscribeButton = () => (
    <ToggleIcon
      toggled={this.props.discussion.subscribed}
      OnIcon={
        <Text color="brand">
          <IconRssSolid title={I18n.t('Unsubscribe from %{title}', { title: this.props.discussion.title })} />
        </Text>
      }
      OffIcon={
        <Text color="brand">
          <IconRssLine title={I18n.t('Subscribe to %{title}', { title: this.props.discussion.title })} />
        </Text>
      }
      onToggleOn={() => this.props.onToggleSubscribe(this.props.discussion)}
      onToggleOff={() => this.props.onToggleSubscribe(this.props.discussion)}
      disabled={this.props.discussion.subscription_hold !== undefined}
      className="subscribe-button"
    />
  )

  publishButton = () => (
    this.props.canPublish
    ? (<ToggleIcon
         toggled={this.props.discussion.published}
         OnIcon={
           <Text color="success">
             <IconPublishSolid title={I18n.t('Publish %{title}', { title: this.props.discussion.title })} />
           </Text>
         }
         OffIcon={
           <Text color="secondary">
             <IconUnpublishedLine title={I18n.t('Unpublish %{title}', { title: this.props.discussion.title })} />
           </Text>
         }
         onToggleOn={() => this.props.updateDiscussion(this.props.discussion, {published: true}, {})}
         onToggleOff={() => this.props.updateDiscussion(this.props.discussion, {published: false}, {})}
         className="publish-button"
       />)
    : null
  )

  pinMenuItemDisplay = () => {
    if (this.props.discussion.pinned) {
      return (
        <span aria-hidden='true'>
          <IconPinLine />&nbsp;&nbsp;{I18n.t('Unpin')}
        </span>
      )
    } else {
      return (
        <span aria-hidden='true'>
          <IconPinSolid />&nbsp;&nbsp;{I18n.t('Pin')}
        </span>
      )
    }
  }

  renderIcon = () => {
    if(this.props.discussion.assignment) {
      if(this.props.discussion.published) {
        return (
          <Text color="success" size="large">
            <IconAssignmentLine />
          </Text>
        )
      } else {
        return (
          <Text color="secondary" size="large">
            <IconAssignmentLine />
          </Text>
        )
      }
    }
    return null
  }

  createMenuItem = (itemKey, visibleItemLabel, screenReaderContent) => (
      <MenuItem
        key={itemKey}
        value={{ action: itemKey, id: this.props.discussion.id }}
        id={`${itemKey}-discussion-menu-option`}
      >
        {visibleItemLabel}
        <ScreenReaderContent>
          {screenReaderContent}
        </ScreenReaderContent>
      </MenuItem>
  )


  renderMenuList = () => {
    const discussionTitle = this.props.discussion.title
    const menuList = []
    if (this.props.displayLockMenuItem) {
      const menuLabel = this.props.discussion.locked ? I18n.t('Open for comments')
        : I18n.t('Close for comments')
      const screenReaderContent = this.props.discussion.locked
        ? I18n.t('Open discussion %{title} for comments', { title: discussionTitle })
        : I18n.t('Close discussion %{title} for comments', { title: discussionTitle })
      menuList.push(this.createMenuItem(
        'togglelocked',
        ( <span aria-hidden='true'> <IconReply />&nbsp;&nbsp;{menuLabel} </span> ),
        screenReaderContent
      ))
    }

    if (this.props.displayPinMenuItem) {
      const screenReaderContent = this.props.discussion.pinned
        ? I18n.t('Unpin discussion %{title}', { title: discussionTitle })
        : I18n.t('Pin discussion %{title}', { title: discussionTitle })
      menuList.push(this.createMenuItem(
        'togglepinned',
        this.pinMenuItemDisplay(),
        screenReaderContent
      ))
    }

    if (this.props.onMoveDiscussion) {
      menuList.push(this.createMenuItem(
        'moveTo',
        ( <span aria-hidden='true'><IconUpdownLine />&nbsp;&nbsp;{I18n.t('Move To')}</span> ),
        I18n.t('Move discussion %{title}', { title: discussionTitle })
      ))
    }

    if (this.props.displayDuplicateMenuItem) {
      menuList.push(this.createMenuItem(
        'duplicate',
        ( <span aria-hidden='true'><IconCopySolid />&nbsp;&nbsp;{I18n.t('Duplicate')}</span> ),
        I18n.t('Duplicate discussion %{title}', { title: discussionTitle })
      ))
    }

    // This returns an empty struct if assignment_id is falsey
    if (this.props.displayMasteryPathsMenuItem) {
      menuList.push(this.createMenuItem(
        'masterypaths',
        ( <span aria-hidden='true'>{ I18n.t('Mastery Paths') }</span> ),
        I18n.t('Edit Mastery Paths for %{title}', { title: discussionTitle })
      ))
    }

    if (this.props.displayDeleteMenuItem) {
      menuList.push(this.createMenuItem(
        'delete',
        ( <span aria-hidden='true'><IconTrashSolid />&nbsp;&nbsp;{I18n.t('Delete')}</span> ),
        I18n.t('Delete discussion %{title}', { title: discussionTitle })
      ))
    }

    return menuList
  }

  render () {
    // necessary because discussions return html from RCE
    const contentWrapper = document.createElement('span')
    contentWrapper.innerHTML = this.props.discussion.message
    const textContent = contentWrapper.textContent.trim()
    return this.props.connectDragPreview (
      <div>
        <Grid startAt="medium" vAlign="middle" colSpacing="none">
          <GridRow>
          {/* discussion topics is different for badges so we use our own read indicator instead of passing to isRead */}
            <GridCol width="auto">
            {!(this.props.discussion.read_state === "read")
              ? <Badge margin="0 small x-small 0" standalone type="notification" />
              : <Container display="block" margin="0 small x-small 0">
            <Container display="block" margin="0 small x-small 0" />
            </Container>}
            </GridCol>
            <GridCol>
              <CourseItemRow
                ref={this.props.rowRef}
                className="ic-discussion-row"
                key={this.props.discussion.id}
                id={this.props.discussion.id}
                isDragging={this.props.isDragging}
                focusOn={this.props.discussion.focusOn}
                draggable={this.props.draggable}
                connectDragSource={this.props.connectDragSource}
                connectDropTarget={this.props.connectDropTarget}
                icon={this.renderIcon() }
                isRead
                author={this.props.discussion.author}
                title={this.props.discussion.title}
                body={textContent ? <div className="ic-discussion-row__content">{textContent}</div> : null}
                sectionToolTip={
                  <SectionsTooltip
                    totalUserCount={this.props.discussion.user_count}
                    sections={this.props.discussion.sections}
                  />
                }
                itemUrl={this.props.discussion.html_url}
                onSelectedChanged={this.props.onSelectedChanged}
                peerReview={this.props.discussion.assignment ? this.props.discussion.assignment.peer_reviews : false}
                showManageMenu={this.props.displayManageMenu}
                onManageMenuSelect={this.onManageDiscussion}
                clearFocusDirectives={this.props.cleanDiscussionFocus}
                manageMenuOptions={this.renderMenuList()}
                masterCourse={{
                  courseData: this.props.masterCourseData || {},
                  getLockOptions: () => ({
                    model: new DiscussionModel(this.props.discussion),
                    unlockedText: I18n.t('%{title} is unlocked. Click to lock.', {title: this.props.discussion.title}),
                    lockedText: I18n.t('%{title} is locked. Click to unlock', {title: this.props.discussion.title}),
                    course_id: this.props.masterCourseData.masterCourse.id,
                    content_id: this.props.discussion.id,
                    content_type: 'discussion_topic',
                  }),
                }}
                metaContent={
                  <div>
                    <span className="ic-item-row__meta-content-heading">
                      <Text size="small" as="p">{makeTimestamp(this.props.discussion).title}</Text>
                    </span>
                    <Text color="secondary" size="small" as="p">
                      {$.datetimeString(makeTimestamp(this.props.discussion).date, {format: 'medium'})}
                    </Text>
                  </div>
                }
                actionsContent={[this.readCount(), this.subscribeButton(), this.publishButton()]}
              />
            </GridCol>
          </GridRow>
        </Grid>
      </div>
    )
  }
}

  /* eslint-disable new-cap */
export const DraggableDiscussionRow = compose(
    DropTarget('Discussion', otherTarget, connect => ({
      connectDropTarget: connect.dropTarget()
    })),
    DragSource('Discussion', discussionTarget, (connect, monitor) => ({
      connectDragSource: connect.dragSource(),
      isDragging: monitor.isDragging(),
      connectDragPreview: connect.dragPreview(),
    }))
  )(DiscussionRow)

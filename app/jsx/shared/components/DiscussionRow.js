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
import React from 'react'
import { func, bool } from 'prop-types'
import $ from 'jquery'
import 'jquery.instructure_date_and_time'

import { DragSource } from 'react-dnd';
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
import IconPublishLine from 'instructure-icons/lib/Line/IconPublishLine'
import IconCopySolid from 'instructure-icons/lib/Solid/IconCopySolid'
import IconUpdownLine from 'instructure-icons/lib/Line/IconUpdownLine'
import IconPinSolid from 'instructure-icons/lib/Solid/IconPinSolid'
import IconPinLine from 'instructure-icons/lib/Line/IconPinLine'
import IconReply from 'instructure-icons/lib/Line/IconReplyLine'

import DiscussionModel from 'compiled/models/DiscussionTopic'
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

export default function DiscussionRow ({ discussion, masterCourseData, rowRef, onSelectedChanged,
                                         connectDragSource, connectDragPreview, draggable,
                                         onToggleSubscribe, updateDiscussion, canManage, canPublish,

                                         duplicateDiscussion, cleanDiscussionFocus, onMoveDiscussion }) {
  const makePinSuccessFailMessages = () => {
    const successMessage = discussion.pinned ?
      I18n.t('Unpin of discussion %{title} succeeded', { title: discussion.title }) :
      I18n.t('Pin of discussion %{title} succeeded', { title: discussion.title })
    const failMessage = discussion.pinned ?
      I18n.t('Unpin of discussion %{title} failed', { title: discussion.title }) :
      I18n.t('Pin of discussion %{title} failed', { title: discussion.title })
    return { successMessage, failMessage }
  }

  const onManageDiscussion = (e, { action, id }) => {
    switch (action) {
     case 'duplicate':
       duplicateDiscussion(id)
       break
     case 'moveTo':
       onMoveDiscussion({ id, title: discussion.title })
       break
     case 'togglepinned':
       updateDiscussion(discussion, { pinned: !discussion.pinned },
         makePinSuccessFailMessages(discussion), 'manageMenu')
       break
     case 'togglelocked':
       updateDiscussion(discussion, { locked: !discussion.locked },
         makePinSuccessFailMessages(discussion), 'manageMenu')
       break
     default:
       throw new Error(I18n.t('Unknown manage discussion action encountered'))
    }
  }

  const timestamp = makeTimestamp(discussion)
  const readCount = discussion.discussion_subentry_count > 0
    ? (
      <UnreadBadge
        unreadCount={discussion.unread_count}
        unreadLabel={I18n.t('%{count} unread replies', { count: discussion.unread_count })}
        totalCount={discussion.discussion_subentry_count}
        totalLabel={I18n.t('%{count} replies', { count: discussion.discussion_subentry_count })}
      />
    )
    : null
  const subscribeButton = (
    <ToggleIcon
      toggled={discussion.subscribed}
      OnIcon={<IconRssSolid title={I18n.t('Unsubscribe from %{title}', { title: discussion.title })} />}
      OffIcon={<IconRssLine title={I18n.t('Subscribe to %{title}', { title: discussion.title })} />}
      onToggleOn={() => onToggleSubscribe(discussion)}
      onToggleOff={() => onToggleSubscribe(discussion)}
      disabled={discussion.subscription_hold !== undefined}
      className="subscribe-button"
    />
  )
  const publishButton = canPublish
    ? (<ToggleIcon
         toggled={discussion.published}
         OnIcon={<IconPublishSolid title={I18n.t('Publish %{title}', { title: discussion.title })} />}
         OffIcon={<IconPublishLine title={I18n.t('Unpublish %{title}', { title: discussion.title })} />}
         onToggleOn={() => updateDiscussion(discussion, {published: true}, {})}
         onToggleOff={() => updateDiscussion(discussion, {published: false}, {})}
         className="publish-button"
       />)
    : null

  const pinMenuItemDisplay = () =>{
    if (discussion.pinned) {
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

  const menuList = [
    <MenuItem
      key="duplicate"
      value={{ action: 'duplicate', id: discussion.id }}
      id="duplicate-discussion-menu-option"
    >
      <span aria-hidden='true'>
        <IconCopySolid />&nbsp;&nbsp;{I18n.t('Duplicate')}
      </span>
      <ScreenReaderContent> { I18n.t('Duplicate discussion %{title}', { title: discussion.title }) } </ScreenReaderContent>
    </MenuItem>,
    <MenuItem
      key="togglepinned"
      value={{ action: 'togglepinned', id: discussion.id }}
      id="togglepinned-discussion-menu-option"
    >
      {pinMenuItemDisplay()}
      <ScreenReaderContent>
      { discussion.pinned
        ? I18n.t('Unpin discussion %{title}', { title: discussion.title })
        : I18n.t('Pin discussion %{title}', { title: discussion.title })}
      </ScreenReaderContent>
    </MenuItem>,
    <MenuItem
      key="togglelocked"
      value={{ action: 'togglelocked', id: discussion.id }}
      id="togglelocked-discussion-menu-option"
    >
      <span aria-hidden='true'>
        <IconReply />&nbsp;&nbsp;{ discussion.locked
          ? I18n.t('Open for comments')
          : I18n.t('Close for comments') }
      </span>
      <ScreenReaderContent>
      { discussion.locked
        ? I18n.t('Open discussion %{title} for comments', { title: discussion.title })
        : I18n.t('Close discussion %{title} for comments', { title: discussion.title })}
      </ScreenReaderContent>
    </MenuItem>,
  ]

  if(onMoveDiscussion) {
    menuList.push(
      <MenuItem
        key="move"
        value={{ action: 'moveTo', id: discussion.id, title: discussion.title }}
        id="move-discussion-menu-option"
      >
        <span aria-hidden='true'>
          <IconUpdownLine />&nbsp;&nbsp;{I18n.t('Move To')}
        </span>
        <ScreenReaderContent> { I18n.t('Move discussion %{title}', { title: discussion.title }) } </ScreenReaderContent>
      </MenuItem>
    )
  }

  // necessary because discussions return html from RCE
  const contentWrapper = document.createElement('span')
  contentWrapper.innerHTML = discussion.message
  const textContent = contentWrapper.textContent.trim()
  return connectDragPreview (
    <div>
      <Grid startAt="medium" vAlign="middle" colSpacing="none">
        <GridRow>
          {/* discussion topics is different for badges so we use our own read indicator instead of passing to isRead */}
          <GridCol width="auto">
            {!(discussion.read_state === "read")
            ? <Badge margin="0 small x-small 0" standalone type="notification" />
            : <Container display="block" margin="0 small x-small 0">
            <Container display="block" margin="0 small x-small 0" />
          </Container>}
          </GridCol>
          <GridCol>
            <CourseItemRow
              ref={rowRef}
              className="ic-discussion-row"
              key={discussion.id}
              id={discussion.id}
              focusOn={discussion.focusOn}
              draggable={draggable}
              connectDragSource={connectDragSource}
              icon={
                <Text color={draggable ? "success" : "secondary"} size="large">
                  <IconAssignmentLine />
                </Text>
              }
              isRead
              author={discussion.author}
              title={discussion.title}
              body={textContent ? <div className="ic-discussion-row__content">{textContent}</div> : null}
              sectionToolTip={
                <SectionsTooltip
                  totalUserCount={discussion.user_count}
                  sections={discussion.sections}
                />
              }
              itemUrl={discussion.html_url}
              onSelectedChanged={onSelectedChanged}
              showManageMenu={canManage}
              onManageMenuSelect={onManageDiscussion}
              clearFocusDirectives={cleanDiscussionFocus}
              manageMenuOptions={menuList}
              masterCourse={{
                courseData: masterCourseData || {},
                getLockOptions: () => ({
                  model: new DiscussionModel(discussion),
                  unlockedText: I18n.t('%{title} is unlocked. Click to lock.', {title: discussion.title}),
                  lockedText: I18n.t('%{title} is locked. Click to unlock', {title: discussion.title}),
                  course_id: masterCourseData.masterCourse.id,
                  content_id: discussion.id,
                  content_type: 'discussion_topic',
                }),
              }}
              metaContent={
                <div>
                  <span className="ic-item-row__meta-content-heading">
                    <Text size="small" as="p">{timestamp.title}</Text>
                  </span>
                  <Text color="secondary" size="small" as="p">{$.datetimeString(timestamp.date, {format: 'medium'})}</Text>
                </div>
              }
              actionsContent={[readCount, subscribeButton, publishButton]}
            />
          </GridCol>
        </GridRow>
      </Grid>
    </div>
  )
}

DiscussionRow.propTypes = {
  discussion: discussionShape.isRequired,
  masterCourseData: masterCourseDataShape,
  rowRef: func,
  onSelectedChanged: func,
  connectDragSource: func,
  connectDragPreview: func,
  draggable: bool,
  onToggleSubscribe: func.isRequired,
  canManage: bool.isRequired,
  onManageSubscription: func.isRequired,
  duplicateDiscussion: func.isRequired,
  cleanDiscussionFocus: func.isRequired,
  updateDiscussion: func.isRequired,
  canPublish: bool.isRequired,
}

DiscussionRow.defaultProps = {
  connectDragSource (component) {return component},
  masterCourseData: null,
  rowRef () {},
  onSelectedChanged () {},
  connectDragPreview (component) {return component},
}
export const DraggableDiscussionRow = DragSource('Discussion', discussionTarget, (connect, monitor) => ({
  connectDragSource: connect.dragSource(),
  isDragging: monitor.isDragging(),
  connectDragPreview: connect.dragPreview(),
}))(DiscussionRow)

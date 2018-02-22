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
import Text from '@instructure/ui-core/lib/components/Text'
import IconTimer from 'instructure-icons/lib/Line/IconTimerLine'
import IconAssignmentLine from 'instructure-icons/lib/Line/IconAssignmentLine'

import DiscussionModel from 'compiled/models/DiscussionTopic'
import SectionsTooltip from '../SectionsTooltip'
import CourseItemRow from './CourseItemRow'
import UnreadBadge from './UnreadBadge'
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

export default function DiscussionRow ({ discussion, masterCourseData, rowRef, onSelectedChanged, connectDragSource, connectDragPreview, draggable }) {
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

  // necessary because discussions return html from RCE
  const contentWrapper = document.createElement('span')
  contentWrapper.innerHTML = discussion.message
  const textContent = contentWrapper.textContent.trim()
  return connectDragPreview (
    <span>
      <CourseItemRow
        ref={rowRef}
        className="ic-discussion-row"
        id={discussion.id}
        draggable={draggable}
        connectDragSource={connectDragSource}
        icon={
          <Text color={draggable ? "success" : "secondary"} size="large">
            <IconAssignmentLine />
          </Text>
        }
        isRead={discussion.read_state === 'read'}
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
        actionsContent={readCount}
      />
    </span>
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

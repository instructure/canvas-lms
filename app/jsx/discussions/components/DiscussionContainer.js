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

import React, { Component } from 'react'
import { DropTarget } from 'react-dnd';
import { string, func, bool, arrayOf } from 'prop-types'
import I18n from 'i18n!discussions_v2'

import ToggleDetails from '@instructure/ui-core/lib/components/ToggleDetails'
import Text from '@instructure/ui-core/lib/components/Text'

import DiscussionRow, { DraggableDiscussionRow } from '../../shared/components/DiscussionRow'
import { discussionList } from '../../shared/proptypes/discussion'
import masterCourseDataShape from '../../shared/proptypes/masterCourseData'
import propTypes from '../propTypes'

// We need to look at the previous state of a discussion as well as where it is
// trying to be drag and dropped into in order to create a decent screenreader
// success and fail message
const generateDragAndDropMessages = (props, discussion) => {
  if (props.pinned) {
    return {
      successMessage: I18n.t('Discussion pinned successfully'),
      failMessage: I18n.t('Failed to pin discussion'),
    }
  } else if (discussion.pinned) {
    return {
      successMessage: I18n.t('Discussion unpinned successfully'),
      failMessage: I18n.t('Failed to unpin discussion'),
    }
  } else if (props.closedState) {
    return {
      successMessage: I18n.t('Discussion opened for comments successfully'),
      failMessage: I18n.t('Failed to open discussion for comments'),
    }
  } else {
    return {
      successMessage: I18n.t('Discussion closed for comments successfully'),
      failMessage: I18n.t('Failed to close discussion for comments'),
    }
  }
}

// Handle drag and drop on a discussion. The props passed in tell us how we
// should update the discussion if something is dragged into this container
const discussionTarget = {
  drop(props, monitor) {
    const discussion = monitor.getItem()
    const updateFields = {}
    if (props.closedState !== undefined) updateFields.locked = props.closedState
    if (props.pinned !== undefined) updateFields.pinned =  props.pinned
    const flashMessages = generateDragAndDropMessages(props, discussion)
    props.updateDiscussion(discussion, updateFields, flashMessages)
  },
}

export default class DiscussionsContainer extends Component {
  static propTypes = {
    discussions: discussionList.isRequired,
    permissions: propTypes.permissions.isRequired,
    masterCourseData: masterCourseDataShape,
    title: string.isRequired,
    toggleSubscribe: func.isRequired,
    updateDiscussion: func.isRequired,
    pinned: bool,
    closedState: bool,
    connectDropTarget: func,
    roles: arrayOf(string),
  }

  static defaultProps = {
    masterCourseData: null,
    connectDropTarget (component) {return component},
    pinned: undefined,
    closedState: undefined,
    roles: ['user', 'student'],
  }

  renderDiscussions () {
    return this.props.discussions.map(discussion => {
      if (this.props.permissions.moderate) {
        return (
          <DraggableDiscussionRow
            key={discussion.id}
            discussion={discussion}
            canManage={this.props.permissions.manage_content}
            masterCourseData={this.props.masterCourseData}
            onToggleSubscribe={this.props.toggleSubscribe}
            draggable
          />
        )
      } else {
        return (
          <DiscussionRow
            key={discussion.id}
            discussion={discussion}
            canManage={this.props.permissions.manage_content}
            masterCourseData={this.props.masterCourseData}
            onToggleSubscribe={this.props.toggleSubscribe}
            draggable={false}
          />
        )
      }
    })
  }

  renderPlaceholder() {
    return (
      <div className="discussions-v2__placeholder">
        <Text color="secondary"> placeholder </Text>
      </div>
    )
  }

  render () {
    return this.props.connectDropTarget (
      <div className="discussions-container__wrapper">
        <ToggleDetails
          defaultExpanded
          summary={<Text weight="bold">{this.props.title}</Text>}
        >
            {
              this.props.discussions.length
                ? this.renderDiscussions()
                : this.renderPlaceholder()
            }
        </ToggleDetails>
      </div>
    )
  }
}

export const DroppableDiscussionsContainer = DropTarget('Discussion', discussionTarget, (dragConnect, monitor) => ({
  connectDropTarget: dragConnect.dropTarget(),
  isOver: monitor.isOver(),
  canDrop: monitor.canDrop(),
}))(DiscussionsContainer)

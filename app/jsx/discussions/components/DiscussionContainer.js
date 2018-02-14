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

import ToggleDetails from '@instructure/ui-core/lib/components/ToggleDetails'
import Text from '@instructure/ui-core/lib/components/Text'

import DiscussionRow, { DraggableDiscussionRow } from '../../shared/components/DiscussionRow'
import { discussionList } from '../../shared/proptypes/discussion'
import masterCourseDataShape from '../../shared/proptypes/masterCourseData'
import propTypes from '../propTypes'
import DRAG_AND_DROP_ROLES from '../../shared/DragAndDropRoles'

const discussionTarget = {
  drop(props, monitor) {
    monitor.getItem()
    if (props.togglePin) {
      props.togglePin({discussion: monitor.getItem(), pinnedState: props.pinned, closedState: props.closedState})
    } else {
      props.closeForComments({discussion: monitor.getItem(), closedState: props.closedState, pinnedState: props.pinned})
    }
  },
}

const includesRoles = (role) => DRAG_AND_DROP_ROLES.includes(role)

export default class DiscussionsContainer extends Component {
  static propTypes = {
    discussions: discussionList.isRequired,
    permissions: propTypes.permissions.isRequired,
    masterCourseData: masterCourseDataShape,
    title: string.isRequired,
    togglePin: func,
    toggleSubscribe: func.isRequired,
    closeForComments: func,
    pinned: bool,
    closedState: bool,
    connectDropTarget: func,
    roles: arrayOf(string),
  }

  static defaultProps = {
    masterCourseData: null,
    connectDropTarget (component) {return component},
    pinned: false,
    closedState: false,
    togglePin: null,
    roles: ['user', 'student'],
    closeForComments: () => {},
  }

  renderDiscussions () {
    return this.props.discussions.map(discussion => {
      if (this.props.roles.some(includesRoles)){
        return (<DraggableDiscussionRow
          key={discussion.id}
          discussion={discussion}
          canManage={this.props.permissions.manage_content}
          masterCourseData={this.props.masterCourseData}
          onToggleSubscribe={this.props.toggleSubscribe}
          draggable
        />)
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

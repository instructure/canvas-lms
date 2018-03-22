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
import update from 'immutability-helper'

import DiscussionRow, { DraggableDiscussionRow } from '../../shared/components/DiscussionRow'
import { discussionList } from '../../shared/proptypes/discussion'
import masterCourseDataShape from '../../shared/proptypes/masterCourseData'
import propTypes from '../propTypes'


// Handle drag and drop on a discussion. The props passed in tell us how we
// should update the discussion if something is dragged into this container
const discussionTarget = {
  drop(props, monitor, component) {
    const discussion = monitor.getItem()
    const updateFields = {}
    if (props.closedState !== undefined) updateFields.locked = props.closedState
    if (props.pinned !== undefined) updateFields.pinned =  props.pinned

    // We currently cannot drag an item from a different container to a specific
    // position in the pinned container, thus we only need to set the order when
    // rearranging items in the pinned container, not when dragging a locked or
    // unpinned discussion to the pinned container.
    const order = (props.pinned && discussion.pinned)
      ? component.state.discussions.map(d => d.id)
      : undefined
    props.handleDrop(discussion, updateFields, order)
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
    handleDrop: func, // eslint-disable-line
    duplicateDiscussion: func.isRequired,
    cleanDiscussionFocus: func.isRequired,
    pinned: bool,
    closedState: bool, // eslint-disable-line
    connectDropTarget: func,
    roles: arrayOf(string), // eslint-disable-line
    renderContainerBackground: func.isRequired,
    onMoveDiscussion: func,
    deleteDiscussion: func,
  }

  static defaultProps = {
    masterCourseData: null,
    connectDropTarget (component) {return component},
    pinned: undefined,
    closedState: undefined,
    roles: ['user', 'student'],
    onMoveDiscussion: null,
    deleteDiscussion: null,
    handleDrop: undefined,
  }

  constructor(props) {
    super(props)
    this.moveCard = this.moveCard.bind(this)
    this.state = {
      discussions: props.discussions,
    }
  }

  componentWillReceiveProps(props) {
    if((this.props.discussions.length >= 1
      && props.discussions.length === 0)
      || (props.discussions[0]
      && props.discussions[0].focusOn === "toggleButton")) {
      if(this.toggleBtn) {
        setTimeout(() => {
          this.toggleBtn.focus()
          this.props.cleanDiscussionFocus()
        });
      }
    }

    if(this.props.discussions !== props.discussions) {
      this.setState({
        discussions: props.discussions,
      })
    }
  }

  wrapperToggleRef = (c) => {
    this.toggleBtn = c && c.querySelector('button')
  }

  moveCard(dragIndex, hoverIndex) {
    const { discussions } = this.state
    const dragDiscussion = discussions[dragIndex]
    if (!dragDiscussion) {
      return
    }
    const newDiscussions = update(this.state, {
      discussions: {
        $splice: [[dragIndex, 1], [hoverIndex, 0, dragDiscussion]],
      },
    })
    newDiscussions.discussions = newDiscussions.discussions.map((discussion, index) => ({...discussion, sortableId: index}))
    this.setState({discussions: newDiscussions.discussions})
  }

  renderDiscussions () {
    return this.state.discussions.reduce((accumlator, discussion) => {
      if (discussion.filtered) { return accumlator }
      const row = this.props.permissions.moderate
        ? <DraggableDiscussionRow
            key={discussion.id}
            discussion={discussion}
            canManage={this.props.permissions.manage_content}
            canPublish={this.props.permissions.publish}
            masterCourseData={this.props.masterCourseData}
            onToggleSubscribe={this.props.toggleSubscribe}
            duplicateDiscussion={this.props.duplicateDiscussion}
            cleanDiscussionFocus={this.props.cleanDiscussionFocus}
            updateDiscussion={this.props.updateDiscussion}
            onMoveDiscussion={this.props.onMoveDiscussion}
            deleteDiscussion={this.props.deleteDiscussion}
            moveCard={this.moveCard}
            draggable
          />
        : <DiscussionRow
            key={discussion.id}
            discussion={discussion}
            canManage={this.props.permissions.manage_content}
            canPublish={this.props.permissions.publish}
            masterCourseData={this.props.masterCourseData}
            onToggleSubscribe={this.props.toggleSubscribe}
            cleanDiscussionFocus={this.props.cleanDiscussionFocus}
            duplicateDiscussion={this.props.duplicateDiscussion}
            updateDiscussion={this.props.updateDiscussion}
            onMoveDiscussion={this.props.onMoveDiscussion}
            deleteDiscussion={this.props.deleteDiscussion}
            draggable={false}
          />
      accumlator.push(row)
      return accumlator
    }, [])
  }

  renderBackgroundImage() {
    return (
      <div className="discussions-v2__container-image">
        {this.props.renderContainerBackground()}
      </div>
    )
  }

  render () {
    return this.props.connectDropTarget (
      <div className="discussions-container__wrapper">
        {!this.props.pinned ?
        <span className="recent-activity-text-container">
          <Text fontStyle="italic">{I18n.t('Ordered by Recent Activity')}</Text>
        </span> : null }
        <span ref={this.wrapperToggleRef}>
          <ToggleDetails
            defaultExpanded
            summary={<Text weight="bold">{this.props.title}</Text>}
          >
              {
                this.props.discussions.filter(d => !d.filtered).length
                  ? this.renderDiscussions()
                  : this.renderBackgroundImage()
              }
          </ToggleDetails>
        </span>
      </div>
    )
  }
}

export const DroppableDiscussionsContainer = DropTarget('Discussion', discussionTarget, (dragConnect, monitor) => ({
  connectDropTarget: dragConnect.dropTarget(),
  isOver: monitor.isOver(),
  canDrop: monitor.canDrop(),
}))(DiscussionsContainer)

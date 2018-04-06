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
import CyoeHelper from '../../shared/conditional_release/CyoeHelper'

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
    cleanDiscussionFocus: func.isRequired,
    closedState: bool, // eslint-disable-line
    connectDropTarget: func,
    contextType: string.isRequired,
    deleteDiscussion: func,
    deleteFocusDone: func.isRequired,
    deleteFocusPending: bool.isRequired, // eslint-disable-line
    discussionTopicMenuTools: arrayOf(propTypes.discussionTopicMenuTools),
    discussions: discussionList.isRequired,
    duplicateDiscussion: func.isRequired,
    handleDrop: func, // eslint-disable-line
    masterCourseData: masterCourseDataShape,
    onMoveDiscussion: func,
    permissions: propTypes.permissions.isRequired,
    pinned: bool,
    renderContainerBackground: func.isRequired,
    roles: arrayOf(string), // eslint-disable-line
    title: string.isRequired,
    toggleSubscribe: func.isRequired,
    updateDiscussion: func.isRequired,
  }

  static defaultProps = {
    masterCourseData: null,
    connectDropTarget (component) {return component},
    pinned: undefined,
    closedState: undefined,
    roles: ['user', 'student'],
    onMoveDiscussion: null,
    discussionTopicMenuTools: [],
    deleteDiscussion: null,
    handleDrop: undefined,
  }

  constructor(props) {
    super(props)
    this.moveCard = this.moveCard.bind(this)
    this.state = {
      discussions: props.discussions,
      expanded: true,
    }
  }

  componentWillReceiveProps(props) {
    if(this.props.discussions === props.discussions) { return }
    this.setState({ discussions: props.discussions, expanded: true })
    this.handleDeleteFocus(props)
  }

  wrapperToggleRef = (c) => {
    this.toggleBtn = c && c.querySelector('button')
  }

  toggleExpanded = () => {
    this.setState({expanded: !this.state.expanded})
  }

  handleDeleteFocus(newProps) {
    // Set the focus to the container toggle button if we are deleting an element,
    // and the new discussions list is empty or explictly said to set focus to
    // that toggle button.
    if (!this.toggleBtn) { return }
    if (!newProps.deleteFocusPending) { return }
    if (this.props.discussions.length === 0) { return }

    if (newProps.discussions.length === 0 || newProps.discussions[0].focusOn === "toggleButton") {
      this.toggleBtn.focus()
      this.props.cleanDiscussionFocus()
      this.props.deleteFocusDone()
    }
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
      const cyoe = CyoeHelper.getItemData(discussion.assignment_id)
      const row = this.props.permissions.moderate
        ? <DraggableDiscussionRow
            key={discussion.id}
            discussion={discussion}
            displayManageMenu={discussion.permissions.delete}
            displayPinMenuItem={this.props.permissions.moderate}
            displayDuplicateMenuItem={this.props.permissions.manage_content}
            displayLockMenuItem={discussion.can_lock}
            displayDeleteMenuItem={
              !(discussion.is_master_course_child_content && discussion.restricted_by_master_course)
            }
            displayMasteryPathsMenuItem={cyoe.isCyoeAble}
            canPublish={this.props.permissions.publish}
            masterCourseData={this.props.masterCourseData}
            onToggleSubscribe={this.props.toggleSubscribe}
            duplicateDiscussion={this.props.duplicateDiscussion}
            discussionTopicMenuTools={this.props.discussionTopicMenuTools}
            cleanDiscussionFocus={this.props.cleanDiscussionFocus}
            updateDiscussion={this.props.updateDiscussion}
            onMoveDiscussion={this.props.onMoveDiscussion}
            deleteDiscussion={this.props.deleteDiscussion}
            contextType={this.props.contextType}
            moveCard={this.moveCard}
            draggable
          />
        : <DiscussionRow
            key={discussion.id}
            discussion={discussion}
            displayManageMenu={discussion.permissions.delete}
            displayPinMenuItem={this.props.permissions.moderate}
            displayDuplicateMenuItem={this.props.permissions.manage_content}
            displayLockMenuItem={discussion.can_lock}
            displayDeleteMenuItem={
              !(discussion.is_master_course_child_content && discussion.restricted_by_master_course)
            }
            displayMasteryPathsMenuItem={cyoe.isCyoeAble}
            canPublish={this.props.permissions.publish}
            masterCourseData={this.props.masterCourseData}
            discussionTopicMenuTools={this.props.discussionTopicMenuTools}
            onToggleSubscribe={this.props.toggleSubscribe}
            cleanDiscussionFocus={this.props.cleanDiscussionFocus}
            duplicateDiscussion={this.props.duplicateDiscussion}
            updateDiscussion={this.props.updateDiscussion}
            onMoveDiscussion={this.props.onMoveDiscussion}
            deleteDiscussion={this.props.deleteDiscussion}
            contextType={this.props.contextType}
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
            expanded={this.state.expanded}
            onToggle={this.toggleExpanded}
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

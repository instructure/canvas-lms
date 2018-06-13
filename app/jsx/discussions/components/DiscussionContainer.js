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
import {connect} from 'react-redux'
import {bindActionCreators} from 'redux'
import { DropTarget } from 'react-dnd';
import { string, func, bool } from 'prop-types'
import I18n from 'i18n!discussions_v2'
import moment from 'moment'

import ToggleDetails from '@instructure/ui-toggle-details/lib/components/ToggleDetails'
import Text from '@instructure/ui-elements/lib/components/Text'
import update from 'immutability-helper'

import select from '../../shared/select'
import actions from '../actions'
import { ConnectedDiscussionRow, ConnectedDraggableDiscussionRow } from './DiscussionRow'
import { discussionList } from '../../shared/proptypes/discussion'
import propTypes from '../propTypes'


// Handle drag and drop on a discussion. The props passed in tell us how we
// should update the discussion if something is dragged into this container
export const discussionTarget = {
  // TODO test this method now that we export this discussion target
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
  canDrop(props, monitor) {
    if (props.closedState && monitor.getItem().assignment) {
      return moment(monitor.getItem().assignment.due_at) < moment()
    }
    return true
  },
}

export class DiscussionsContainer extends Component {
  static propTypes = {
    cleanDiscussionFocus: func.isRequired,
    closedState: bool, // eslint-disable-line
    connectDropTarget: func,
    deleteDiscussion: func.isRequired,
    deleteFocusDone: func.isRequired,
    deleteFocusPending: bool.isRequired, // eslint-disable-line
    discussions: discussionList.isRequired,
    handleDrop: func, // eslint-disable-line
    onMoveDiscussion: func,
    permissions: propTypes.permissions.isRequired,
    pinned: bool,
    renderContainerBackground: func.isRequired,
    title: string.isRequired,
  }

  static defaultProps = {
    closedState: undefined,
    connectDropTarget (component) {return component},
    handleDrop: undefined,
    onMoveDiscussion: null,
    pinned: undefined,
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

  getDiscussionPosition = (discussion) => {
    const { id } = discussion
    return this.state.discussions.findIndex((d) => d.id === id)
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

  wrapperToggleRef = (c) => {
    this.toggleBtn = c && c.querySelector('button')
  }

  moveCard(dragIndex, hoverIndex) {
    // Only pinned discussions can be repositioned, others are sorted by
    // recent activity
    if (!this.props.pinned) { return }

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
    this.setState({discussions: newDiscussions.discussions})
  }

  renderDiscussions () {
    return this.state.discussions.map((discussion) => (
      this.props.permissions.moderate
        ? <ConnectedDraggableDiscussionRow
            key={discussion.id}
            discussion={discussion}
            deleteDiscussion={this.props.deleteDiscussion}
            getDiscussionPosition={this.getDiscussionPosition}
            onMoveDiscussion={this.props.onMoveDiscussion}
            moveCard={this.moveCard}
            draggable
          />
        : <ConnectedDiscussionRow
            key={discussion.id}
            discussion={discussion}
            deleteDiscussion={this.props.deleteDiscussion}
            onMoveDiscussion={this.props.onMoveDiscussion}
            draggable={false}
          />
    ))
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
        <span ref={this.wrapperToggleRef}>
          <ToggleDetails
            expanded={this.state.expanded}
            onToggle={this.toggleExpanded}
            summary={<Text weight="bold" as="h2">{this.props.title}</Text>}
          >
            {!this.props.pinned ?
            <span className="recent-activity-text-container">
              <Text fontStyle="italic">{I18n.t('Ordered by Recent Activity')}</Text>
            </span> : null }
            {this.props.discussions.length ? this.renderDiscussions() : this.renderBackgroundImage()}
          </ToggleDetails>
        </span>
      </div>
    )
  }
}

export const mapState = (state, ownProps) => {
  // Filter out any discussions that are filtered here to keep things simplier
  // in the render calls
  const { discussions } = ownProps
  const filteredDiscussions = discussions.filter((d) => !d.filtered)

  const propsFromState = {
    contextId: state.contextId,
    deleteFocusPending: state.deleteFocusPending,
    discussions: filteredDiscussions,
    permissions: state.permissions,
  }
  return Object.assign({}, ownProps, propsFromState)
}

const mapDispatch = (dispatch) => {
  const actionKeys = [
    'cleanDiscussionFocus',
    'deleteFocusDone',
    'handleDrop',
  ]
  return bindActionCreators(select(actions, actionKeys), dispatch)
}

export const DroppableDiscussionsContainer = DropTarget('Discussion', discussionTarget, (dragConnect, monitor) => ({
  connectDropTarget: dragConnect.dropTarget(),
  isOver: monitor.isOver(),
  canDrop: monitor.canDrop(),
}))(DiscussionsContainer)

export const ConnectedDiscussionsContainer = connect(
  mapState,
  mapDispatch
)(DiscussionsContainer)

export const DroppableConnectedDiscussionsContainer = connect(
  mapState,
  mapDispatch
)(DroppableDiscussionsContainer)

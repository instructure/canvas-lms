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

import React, {Component} from 'react'
import {connect} from 'react-redux'
import {bindActionCreators} from 'redux'
import {DropTarget} from 'react-dnd'
import {string, func, bool} from 'prop-types'
import {useScope as createI18nScope} from '@canvas/i18n'
import moment from 'moment'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

import {ToggleDetails} from '@instructure/ui-toggle-details'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import update from 'immutability-helper'

import select from '@canvas/obj-select'
import actions from '../actions'
import {ConnectedDiscussionRow, ConnectedDraggableDiscussionRow} from './DiscussionRow'
import {discussionList} from '../proptypes/discussion'
import propTypes from '../propTypes'

const I18n = createI18nScope('discussions_v2')

// Handle drag and drop on a discussion. The props passed in tell us how we
// should update the discussion if something is dragged into this container
export const discussionTarget = {
  // TODO test this method now that we export this discussion target
  // @ts-expect-error TS7006 (typescriptify)
  drop(props, monitor, component) {
    const discussion = monitor.getItem()
    const updateFields = {}
    // @ts-expect-error TS2339 (typescriptify)
    if (props.closedState !== undefined) updateFields.locked = props.closedState
    // @ts-expect-error TS2339 (typescriptify)
    if (props.pinned !== undefined) updateFields.pinned = props.pinned

    // We currently cannot drag an item from a different container to a specific
    // position in the pinned container, thus we only need to set the order when
    // rearranging items in the pinned container, not when dragging a locked or
    // unpinned discussion to the pinned container.
    const order =
      // @ts-expect-error TS7006 (typescriptify)
      props.pinned && discussion.pinned ? component.state.discussions.map(d => d.id) : undefined
    props.handleDrop(discussion, updateFields, order)
  },
  // @ts-expect-error TS7006 (typescriptify)
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
    // this really is used
    closedState: bool,
    connectDropTarget: func,
    deleteDiscussion: func.isRequired,
    deleteFocusDone: func.isRequired,
    // this really is used
    deleteFocusPending: bool.isRequired,
    discussions: discussionList.isRequired,
    // this really is used
    handleDrop: func,
    onMoveDiscussion: func,
    onOpenAssignToTray: func,
    permissions: propTypes.permissions.isRequired,
    pinned: bool,
    renderContainerBackground: func.isRequired,
    title: string.isRequired,
  }

  static defaultProps = {
    closedState: undefined,
    // @ts-expect-error TS7006 (typescriptify)
    connectDropTarget(component) {
      return component
    },
    handleDrop: undefined,
    onMoveDiscussion: null,
    onOpenAssignToTray: null,
    pinned: undefined,
  }

  // @ts-expect-error TS7006 (typescriptify)
  constructor(props) {
    super(props)
    this.state = {
      discussions: props.discussions,
      expanded: true,
    }
  }

  // @ts-expect-error TS7006 (typescriptify)
  UNSAFE_componentWillReceiveProps(props) {
    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.discussions === props.discussions) {
      return
    }
    this.setState({discussions: props.discussions, expanded: true})
    this.handleDeleteFocus(props)
  }

  // @ts-expect-error TS7006 (typescriptify)
  getDiscussionPosition = discussion => {
    const {id} = discussion
    // @ts-expect-error TS2339,TS7006 (typescriptify)
    return this.state.discussions.findIndex(d => d.id === id)
  }

  toggleExpanded = () => {
    // @ts-expect-error TS2339 (typescriptify)
    this.setState({expanded: !this.state.expanded})
  }

  // @ts-expect-error TS7006 (typescriptify)
  handleDeleteFocus(newProps) {
    // Set the focus to the container toggle button if we are deleting an element,
    // and the new discussions list is empty or explictly said to set focus to
    // that toggle button.
    // @ts-expect-error TS2339 (typescriptify)
    if (!this.toggleBtn) {
      return
    }
    if (!newProps.deleteFocusPending) {
      return
    }
    // @ts-expect-error TS2339 (typescriptify)
    if (this.props.discussions.length === 0) {
      return
    }

    if (newProps.discussions.length === 0 || newProps.discussions[0].focusOn === 'toggleButton') {
      // @ts-expect-error TS2339 (typescriptify)
      this.toggleBtn.focus()
      // @ts-expect-error TS2339 (typescriptify)
      this.props.cleanDiscussionFocus()
      // @ts-expect-error TS2339 (typescriptify)
      this.props.deleteFocusDone()
    }
  }

  // @ts-expect-error TS7006 (typescriptify)
  wrapperToggleRef = c => {
    // @ts-expect-error TS2339 (typescriptify)
    this.toggleBtn = c && c.querySelector('button')
  }

  // @ts-expect-error TS7006 (typescriptify)
  moveCard = (dragIndex, hoverIndex) => {
    // Only pinned discussions can be repositioned, others are sorted by
    // recent activity
    // @ts-expect-error TS2339 (typescriptify)
    if (!this.props.pinned) {
      return
    }

    // @ts-expect-error TS2339 (typescriptify)
    const {discussions} = this.state
    const dragDiscussion = discussions[dragIndex]
    if (!dragDiscussion) {
      return
    }

    const newDiscussions = update(this.state, {
      discussions: {
        $splice: [
          [dragIndex, 1],
          [hoverIndex, 0, dragDiscussion],
        ],
      },
    })
    // @ts-expect-error TS2339 (typescriptify)
    this.setState({discussions: newDiscussions.discussions})
  }

  renderDiscussions() {
    // @ts-expect-error TS2339,TS7006 (typescriptify)
    return this.state.discussions.map(discussion =>
      // @ts-expect-error TS2339 (typescriptify)
      this.props.permissions.moderate ? (
        <div data-testid="discussion-draggable-row-container" key={discussion.id}>
          <ConnectedDraggableDiscussionRow
            discussion={discussion}
            // @ts-expect-error TS2339 (typescriptify)
            deleteDiscussion={this.props.deleteDiscussion}
            getDiscussionPosition={this.getDiscussionPosition}
            // @ts-expect-error TS2339 (typescriptify)
            onMoveDiscussion={this.props.onMoveDiscussion}
            // @ts-expect-error TS2339 (typescriptify)
            onOpenAssignToTray={this.props.onOpenAssignToTray}
            moveCard={this.moveCard}
            draggable={true}
          />
        </div>
      ) : (
        <div data-testid="discussion-row-container" key={discussion.id}>
          <ConnectedDiscussionRow
            discussion={discussion}
            // @ts-expect-error TS2339 (typescriptify)
            deleteDiscussion={this.props.deleteDiscussion}
            // @ts-expect-error TS2339 (typescriptify)
            onMoveDiscussion={this.props.onMoveDiscussion}
            // @ts-expect-error TS2339 (typescriptify)
            onOpenAssignToTray={this.props.onOpenAssignToTray}
            draggable={false}
          />
        </div>
      ),
    )
  }

  renderBackgroundImage() {
    return (
      <div className="discussions-v2__container-image">
        {/* @ts-expect-error TS2339 (typescriptify) */}
        {this.props.renderContainerBackground()}
      </div>
    )
  }

  render() {
    // @ts-expect-error TS2339 (typescriptify)
    const titleKebab = this.props.title.toLowerCase().replace(/\s+/g, '-')

    // @ts-expect-error TS2339 (typescriptify)
    return this.props.connectDropTarget(
      <div
        className="discussions-container__wrapper"
        data-testid={`discussions-container-${titleKebab}`}
        data-action-state={
          // @ts-expect-error TS2339 (typescriptify)
          this.state.expanded
            ? `discussions-container-${titleKebab}-expanded`
            : `discussions-container-${titleKebab}-collapsed`
        }
      >
        <span ref={this.wrapperToggleRef}>
          <ScreenReaderContent>
            {/* @ts-expect-error TS2339 (typescriptify) */}
            <Heading level="h2">{this.props.title}</Heading>
          </ScreenReaderContent>
          <ToggleDetails
            fluidWidth={true}
            // @ts-expect-error TS2339 (typescriptify)
            expanded={this.state.expanded}
            onToggle={this.toggleExpanded}
            summary={
              <Flex>
                <Flex.Item shouldGrow={true} shouldShrink={true}>
                  {/* @ts-expect-error TS2339 (typescriptify) */}
                  <Text weight="bold">{this.props.title}</Text>
                </Flex.Item>
                {/* @ts-expect-error TS2339 (typescriptify) */}
                {!this.props.pinned ? (
                  <Flex.Item shouldShrink={true} textAlign="end">
                    <span className="recent-activity-text-container">
                      <Text fontStyle="italic">{I18n.t('Ordered by Recent Activity')}</Text>
                    </span>
                  </Flex.Item>
                ) : null}
              </Flex>
            }
          >
            {/* @ts-expect-error TS2339 (typescriptify) */}
            {this.props.discussions.length
              ? this.renderDiscussions()
              : this.renderBackgroundImage()}
          </ToggleDetails>
        </span>
      </div>,
    )
  }
}

// @ts-expect-error TS7006 (typescriptify)
export const mapState = (state, ownProps) => {
  // Filter out any discussions that are filtered here to keep things simplier
  // in the render calls
  const {discussions} = ownProps
  // @ts-expect-error TS7006 (typescriptify)
  const filteredDiscussions = discussions.filter(d => !d.filtered)

  const propsFromState = {
    contextId: state.contextId,
    deleteFocusPending: state.deleteFocusPending,
    discussions: filteredDiscussions,
    permissions: state.permissions,
  }
  return {...ownProps, ...propsFromState}
}

// @ts-expect-error TS7006 (typescriptify)
const mapDispatch = dispatch => {
  const actionKeys = ['cleanDiscussionFocus', 'deleteFocusDone', 'handleDrop']
  // @ts-expect-error TS2769 (typescriptify)
  return bindActionCreators(select(actions, actionKeys), dispatch)
}

export const DroppableDiscussionsContainer = DropTarget(
  'Discussion',
  discussionTarget,
  (dragConnect, monitor) => ({
    connectDropTarget: dragConnect.dropTarget(),
    isOver: monitor.isOver(),
    canDrop: monitor.canDrop(),
  }),
)(DiscussionsContainer)

export const ConnectedDiscussionsContainer = connect(mapState, mapDispatch)(DiscussionsContainer)

export const DroppableConnectedDiscussionsContainer = connect(
  mapState,
  mapDispatch,
)(DroppableDiscussionsContainer)

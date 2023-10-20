/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import React from 'react'
import PropTypes from 'prop-types'
import classNames from 'classnames'
import {DragSource} from 'react-dnd'

import AssignmentMenu from './assignment-card-menu'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('conditional_release')

const {object, bool, func} = PropTypes

// implements the drag source contract
const assignmentSource = {
  canDrag(props) {
    return !!props.assignment
  },

  beginDrag(props) {
    return {
      path: props.path,
      id: props.assignment.get('id').toString(),
    }
  },
}

class AssignmentCard extends React.Component {
  static get propTypes() {
    return {
      path: object.isRequired,
      assignment: object,
      removeAssignment: func.isRequired,
      onDragOver: func.isRequired,
      onDragLeave: func.isRequired,

      // injected by React DnD
      isDragging: bool.isRequired,
      connectDragSource: func.isRequired,
      connectDragPreview: func.isRequired,
    }
  }

  constructor() {
    super()

    this.removeAssignment = this.removeAssignment.bind(this)
    this.handleDragOver = this.handleDragOver.bind(this)
    this.contentRef = React.createRef()
  }

  removeAssignment() {
    this.props.removeAssignment(this.props.path, this.props.assignment)
  }

  handleDragOver() {
    this.props.onDragOver(this.props.path.assignment)
  }

  renderMenu() {
    if (!this.props.assignment) return null
    else {
      return (
        <AssignmentMenu
          assignment={this.props.assignment}
          removeAssignment={this.removeAssignment}
          path={this.props.path}
        />
      )
    }
  }

  itemClass(category) {
    if (category === 'page') {
      return 'document'
    }
    return category
  }

  renderContent() {
    if (this.props.assignment) {
      const points =
        this.props.assignment.get('category') !== 'page'
          ? I18n.t('%{points} pts', {
              points: I18n.n(this.props.assignment.get('points_possible') || 0),
            })
          : ''

      const label = this.props.assignment.get('name')

      return (
        <div className="cr-assignment-card__content" ref={this.contentRef} aria-label={label}>
          <i
            className={`cr-assignment-card__icon icon-${this.itemClass(
              this.props.assignment.get('category')
            )}`}
          />
          <p className="cr-assignment-card__points">{points}</p>
          <p className="cr-assignment-card__title">{this.props.assignment.get('name')}</p>
        </div>
      )
    } else {
      return <p>{I18n.t('Loading..')}</p>
    }
  }

  render() {
    const classes = classNames({
      'cr-assignment-card': true,
      'cr-assignment-card__loading': !this.props.assignment,
      'cr-assignment-card__dragging': this.props.isDragging,
    })

    return this.props.connectDragPreview(
      this.props.connectDragSource(
        <div
          className={classes}
          onDragOver={this.handleKeyDownDragOver}
          onDragLeave={this.props.onDragLeave}
        >
          {this.renderContent()}
          {this.renderMenu()}
        </div>,
        {dropEffect: 'move'}
      ),
      {captureDraggingState: true}
    )
  }
}

export default DragSource('AssignmentCard', assignmentSource, (connect, monitor) => ({
  connectDragSource: connect.dragSource(),
  connectDragPreview: connect.dragPreview(),
  isDragging: monitor.isDragging(),
}))(AssignmentCard)

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
import {DropTarget} from 'react-dnd'

import Assignment from './assignment-card'
import ConditionToggle from './condition-toggle'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

const {object, func, string, bool} = PropTypes

// implements the drop target contract
const assignmentTarget = {
  drop(props, monitor, component) {
    const item = monitor.getItem()
    const assg = component.getAssignmentDropTarget()
    const path = assg !== undefined ? props.path.push(assg) : props.path

    const found = props.setAssignments.find(a => {
      return a.get('assignment_id') === item.id
    })

    const isInternal = item.path.pop().equals(props.path)

    // if (assignment isn't already in set OR is moved within the set) AND isn't dropped on itself..
    if ((!found || isInternal) && !item.path.equals(path)) {
      props.moveAssignment(item.path, path, item.id)
    }

    component.resetAssignmentDropTarget()
  },
}

class AssignmentSet extends React.Component {
  static get propTypes() {
    return {
      path: object.isRequired,
      setAssignments: object.isRequired,
      allAssignments: object.isRequired,
      removeAssignment: func.isRequired,
      moveAssignment: func.isRequired /* eslint-disable-line react/no-unused-prop-types */,
      toggleSetCondition: func.isRequired,
      showOrToggle: bool,
      disableSplit: bool,
      label: string.isRequired,

      // injected by React DnD
      connectDropTarget: func.isRequired,
      isOver: bool.isRequired,
      canDrop: bool.isRequired,
    }
  }

  constructor() {
    super()

    this.state = {
      dropTarget: undefined,
    }

    this.setAssignmentDropTarget = this.setAssignmentDropTarget.bind(this)
    this.resetAssignmentDropTarget = this.resetAssignmentDropTarget.bind(this)
  }

  setAssignmentDropTarget(idx) {
    this.setState({dropTarget: idx})
  }

  resetAssignmentDropTarget() {
    this.setState({dropTarget: undefined})
  }

  getAssignmentDropTarget() {
    return this.state.dropTarget
  }

  renderToggle(path) {
    const isLastAssignment = path.assignment + 1 === this.props.setAssignments.size

    if (path.assignment === this.state.dropTarget) {
      return this.renderDragToggle(isLastAssignment)
    } else if (isLastAssignment && !this.props.showOrToggle) {
      return null
    } else {
      const isAnd = !isLastAssignment
      return (
        <ConditionToggle
          isAnd={isAnd}
          isDisabled={isAnd && this.props.disableSplit}
          path={path}
          handleToggle={this.props.toggleSetCondition}
        />
      )
    }
  }

  renderDragToggle(isLast) {
    return <ConditionToggle isAnd={true} isFake={isLast} />
  }

  renderAssignments() {
    return this.props.setAssignments
      .map((asg, idx) => {
        const assignment = this.props.allAssignments.get(asg.get('assignment_id'))

        const setInnerClasses = classNames({
          'cr-assignment-set__inner': true,
          'cr-assignment-set__inner__draggedOver': idx === this.state.dropTarget,
        })

        const path = this.props.path.push(idx)

        return (
          <div key={asg.get('assignment_id')} className={setInnerClasses}>
            <Assignment
              path={path}
              assignment={assignment}
              removeAssignment={this.props.removeAssignment}
              onDragOver={this.setAssignmentDropTarget}
              onDragLeave={this.resetAssignmentDropTarget}
            />
            {this.renderToggle(path)}
          </div>
        )
      })
      .toArray()
  }

  render() {
    const {canDrop, isOver, connectDropTarget} = this.props

    const setClasses = classNames({
      'cr-assignment-set': true,
      'cr-assignment-set__empty': this.props.setAssignments.size === 0,
      'cr-assignment-set__drag-over': isOver,
      'cr-assignment-set__can-drop': canDrop,
    })

    return connectDropTarget(
      <div className={setClasses} onDragLeave={this.resetAssignmentDropTarget}>
        <ScreenReaderContent>
          <h3>{this.props.label}</h3>
        </ScreenReaderContent>
        {this.renderAssignments()}
      </div>
    )
  }
}

export default DropTarget('AssignmentCard', assignmentTarget, (connect, monitor) => ({
  connectDropTarget: connect.dropTarget(),
  isOver: monitor.isOver(),
  canDrop: monitor.canDrop(),
}))(AssignmentSet)

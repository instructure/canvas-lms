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

import React from 'react'
import {bool, func} from 'prop-types'

import {View} from '@instructure/ui-view'

import {TeacherAssignmentShape} from '../../assignmentData'
import Override from './Override'
import EveryoneElse from './EveryoneElse'

export default class Overrides extends React.Component {
  static propTypes = {
    assignment: TeacherAssignmentShape.isRequired,
    onChangeAssignment: func.isRequired,
    onValidate: func.isRequired,
    invalidMessage: func.isRequired,
    readOnly: bool,
  }

  static defaultProps = {
    readOnly: false,
  }

  handleChangeOverride = (overrideIndex, path, value) => {
    const hoistToAssignment = ['allowedAttempts', 'submissionTypes']
    if (hoistToAssignment.includes(path)) {
      this.props.onChangeAssignment(path, value)
    } else {
      this.props.onChangeAssignment(`assignmentOverrides.nodes.${overrideIndex}.${path}`, value)
    }
  }

  handleValidateEveryoneElse = (_ignore, path, value) => this.props.onValidate(path, value)

  handleValidateOverride = (overrideIndex, path, value) =>
    this.props.onValidate(`assignmentOverrides.nodes.${overrideIndex}.${path}`, value)

  everyoneElseInvalidMessage = (_ignore, path) => this.props.invalidMessage(path)

  invalidMessage = (overrideIndex, path) =>
    this.props.invalidMessage(`assignmentOverrides.nodes.${overrideIndex}.${path}`)

  renderEveryoneElse() {
    return (
      <EveryoneElse
        assignment={this.props.assignment}
        onChangeAssignment={this.props.onChangeAssignment}
        onValidate={this.handleValidateEveryoneElse}
        invalidMessage={this.everyoneElseInvalidMessage}
        readOnly={this.props.readOnly}
      />
    )
  }

  renderOverrides() {
    const assignment = this.props.assignment
    const overrides = assignment.assignmentOverrides.nodes
    if (overrides.length > 0) {
      return overrides.map((override, index) => (
        // in the existing schema submissionTypes, allowedExtensions, and allowedAttempts are on the assignment.
        // eventually, they will also be part of each override
        <Override
          key={override.lid}
          override={{
            ...override,
            submissionTypes: assignment.submissionTypes,
            allowedExtensions: assignment.allowedExtensions,
            allowedAttempts: assignment.allowedAttempts,
          }}
          index={index}
          onChangeOverride={this.handleChangeOverride}
          onValidate={this.handleValidateOverride}
          invalidMessage={this.invalidMessage}
          readOnly={this.props.readOnly}
        />
      ))
    }
    return null
  }

  render() {
    return (
      <View as="div">
        {this.renderOverrides()}
        {this.props.assignment.onlyVisibleToOverrides ? null : this.renderEveryoneElse()}
      </View>
    )
  }
}

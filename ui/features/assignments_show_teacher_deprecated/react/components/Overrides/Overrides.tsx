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

  // @ts-expect-error
  handleChangeOverride = (overrideIndex, path, value) => {
    const hoistToAssignment = ['allowedAttempts', 'submissionTypes']
    if (hoistToAssignment.includes(path)) {
      // @ts-expect-error
      this.props.onChangeAssignment(path, value)
    } else {
      // @ts-expect-error
      this.props.onChangeAssignment(`assignmentOverrides.nodes.${overrideIndex}.${path}`, value)
    }
  }

  // @ts-expect-error
  handleValidateEveryoneElse = (_ignore, path, value) => this.props.onValidate(path, value)

  // @ts-expect-error
  handleValidateOverride = (overrideIndex, path, value) =>
    // @ts-expect-error
    this.props.onValidate(`assignmentOverrides.nodes.${overrideIndex}.${path}`, value)

  // @ts-expect-error
  everyoneElseInvalidMessage = (_ignore, path) => this.props.invalidMessage(path)

  // @ts-expect-error
  invalidMessage = (overrideIndex, path) =>
    // @ts-expect-error
    this.props.invalidMessage(`assignmentOverrides.nodes.${overrideIndex}.${path}`)

  renderEveryoneElse() {
    return (
      <EveryoneElse
        // @ts-expect-error
        assignment={this.props.assignment}
        // @ts-expect-error
        onChangeAssignment={this.props.onChangeAssignment}
        onValidate={this.handleValidateEveryoneElse}
        invalidMessage={this.everyoneElseInvalidMessage}
        // @ts-expect-error
        readOnly={this.props.readOnly}
      />
    )
  }

  renderOverrides() {
    // @ts-expect-error
    const assignment = this.props.assignment
    const overrides = assignment.assignmentOverrides.nodes
    if (overrides.length > 0) {
      // @ts-expect-error
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
          // @ts-expect-error
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
        {/* @ts-expect-error */}
        {this.props.assignment.onlyVisibleToOverrides ? null : this.renderEveryoneElse()}
      </View>
    )
  }
}

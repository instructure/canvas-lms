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

import View from '@instructure/ui-layout/lib/components/View'

import {TeacherAssignmentShape} from '../../assignmentData'
import Override from './Override'
import EveryoneElse from './EveryoneElse'

export default class Overrides extends React.Component {
  static propTypes = {
    assignment: TeacherAssignmentShape.isRequired,
    onChangeAssignment: func.isRequired,
    readOnly: bool
  }

  static defaultProps = {
    readOnly: false
  }

  handleChangeOverride = (overrideIndex, path, value) => {
    if (path === 'allowedAttempts' || path === 'submissionTypes') {
      this.props.onChangeAssignment(path, value)
    } else {
      this.props.onChangeAssignment(`assignmentOverrides.nodes.${overrideIndex}.${path}`, value)
    }
  }

  renderEveryoneElse() {
    if (this.props.assignment.dueAt !== null) {
      return (
        <EveryoneElse
          assignment={this.props.assignment}
          onChangeAssignment={this.props.onChangeAssignment}
          readOnly={this.props.readOnly}
        />
      )
    }
    return null
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
            allowedAttempts: assignment.allowedAttempts
          }}
          index={index}
          onChangeOverride={this.handleChangeOverride}
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
        {this.renderEveryoneElse()}
      </View>
    )
  }
}

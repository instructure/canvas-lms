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
import {useScope as useI18nScope} from '@canvas/i18n'
import {TeacherAssignmentShape} from '../../assignmentData'
import Override from './Override'

const I18n = useI18nScope('assignments_2')

// When all the students are not included in the assignment
// overrides, those that are left out (e.g. everyone else,
// though it could be everyone if there are no overrides)
// get their data from the assignment itself.
export default class EveryoneElse extends React.Component {
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

  handleChangeOverride = (_index, path, value) => {
    // everyone else's values go right on the assignment
    this.props.onChangeAssignment(path, value)
  }

  // see
  // OverrideListPresenter.due_for calling
  // OverrideListPresenter.multiple_due_dates calling
  // assignment.has_active_overrides
  hasActiveOverrides() {
    return (
      this.props.assignment.assignmentOverrides.nodes &&
      this.props.assignment.assignmentOverrides.nodes.length
    )
  }

  overrideFromAssignment(assignment) {
    const title = this.hasActiveOverrides() ? I18n.t('Everyone else') : I18n.t('Everyone')

    const fauxOverride = {
      gid: `assignment_${assignment.id}`,
      lid: `assignment_${assignment._id}`,
      dueAt: assignment.dueAt,
      lockAt: assignment.lockAt,
      unlockAt: assignment.unlockAt,
      title,
      submissionTypes: assignment.submissionTypes,
      allowedAttempts: assignment.allowedAttempts,
      allowedExtensions: assignment.allowedExtensions,
      set: {
        lid: null,
        sectionName: title,
      },
    }
    return fauxOverride
  }

  render() {
    const fauxOverride = this.overrideFromAssignment(this.props.assignment)
    return (
      <Override
        override={fauxOverride}
        onChangeOverride={this.handleChangeOverride}
        onValidate={this.props.onValidate}
        invalidMessage={this.props.invalidMessage}
        index={-1}
        readOnly={this.props.readOnly}
      />
    )
  }
}

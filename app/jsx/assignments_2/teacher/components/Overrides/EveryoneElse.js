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
import {bool} from 'prop-types'
import I18n from 'i18n!assignments_2'
import {TeacherAssignmentShape} from '../../assignmentData'
import Override from './Override'

EveryoneElse.propTypes = {
  assignment: TeacherAssignmentShape.isRequired,
  readOnly: bool
}
EveryoneElse.defaultProps = {
  readOnly: true
}

// When all the students are not included in the assignment
// overrides, those that are left out (e.g. everyone else,
// though it could be everyone if there are no overrides)
// get their data from the assignment itself.
export default function EveryoneElse(props) {
  return OverrideFromAssignment(props.assignment, props.readOnly)
}

function OverrideFromAssignment(assignment, readOnly) {
  const title =
    assignment.assignmentOverrides.nodes.length > 0 ? I18n.t('Everyone else') : I18n.t('Everyone')

  const fauxOverride = {
    gid: `assignment_${assignment.id}`,
    lid: `assignment_${assignment._id}`,
    dueAt: assignment.dueAt,
    lockAt: assignment.lockAt,
    unlockAt: assignment.unlockAt,
    title,
    submissionTypes: assignment.submissionTypes,
    allowedExtensions: assignment.allowedExtensions,
    set: {
      lid: null,
      name: title
    },
    readOnly
  }
  return <Override override={fauxOverride} readOnly={readOnly} />
}

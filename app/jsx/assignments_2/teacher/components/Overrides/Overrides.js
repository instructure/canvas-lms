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
import View from '@instructure/ui-layout/lib/components/View'
import {TeacherAssignmentShape} from '../../assignmentData'
import Override from './Override'
import EveryoneElse from './EveryoneElse'

Overrides.propTypes = {
  assignment: TeacherAssignmentShape.isRequired,
  readOnly: bool
}

Overrides.defaultProps = {
  readOnly: false
}

export default function Overrides(props) {
  return (
    <View as="div">
      {renderOverrides(props.assignment, props.readOnly)}
      {renderEveryoneElse(props.assignment, props.readOnly)}
    </View>
  )
}

function renderEveryoneElse(assignment, readOnly) {
  if (assignment.dueAt !== null) {
    return <EveryoneElse assignment={assignment} readOnly={readOnly} />
  }
  return null
}

function renderOverrides(assignment, readOnly) {
  if (assignment.assignmentOverrides.nodes.length > 0) {
    return assignment.assignmentOverrides.nodes.map(override => (
      // in the existing schema, submissionTypes and allowedExtensions are on the assignment.
      // eventually, they will also be part of each override
      <Override
        key={override.lid}
        override={{
          ...override,
          submissionTypes: assignment.submissionTypes,
          allowedExtensions: assignment.allowedExtensions
        }}
        readOnly={readOnly}
      />
    ))
  }
  return null
}

/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {TEACHER_QUERY, SET_WORKFLOW} from './assignmentData'
import {execute, makePromise} from 'apollo-link'
import {createHttpOnlyLink} from '../../canvas-apollo'

// make this lazy to support testing
let _link = null
function link() {
  if (_link) return _link
  return (_link = createHttpOnlyLink())
}

export function queryAssignment(assignmentLid) {
  return makePromise(
    execute(link(), {
      query: TEACHER_QUERY,
      variables: {assignmentLid}
    })
  )
}

export function setWorkflow(assignment, newWorkflow) {
  return makePromise(
    execute(link(), {
      query: SET_WORKFLOW,
      variables: {id: assignment.lid, workflow: newWorkflow}
    })
  )
}

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
import StudentHeader from './components/StudentHeader'
import AssignmentToggleDetails from '../shared/AssignmentToggleDetails'
import StudentContentTabs from './StudentContentTabs'
import {string} from 'prop-types'
import {Query} from 'react-apollo'
import gql from 'graphql-tag'

export const STUDENT_VIEW_QUERY = gql`
  query GetAssignment($assignmentLid: ID!) {
    assignment: legacyNode(type: Assignment, _id: $assignmentLid) {
      ... on Assignment {
        lid: _id
        gid: id
        name
        description
        dueAt
        pointsPossible
        assignmentGroup {
          name
        }
      }
    }
  }
`

const StudentView = props => (
  <Query query={STUDENT_VIEW_QUERY} variables={{assignmentLid: props.assignmentLid}}>
    {({loading, error, data}) => {
      // TODO HANDLE ERROR AND LOADING
      if (loading) return null
      if (error) return `Error!: ${error}`
      return (
        <div data-test-id="assignments-2-student-view">
          <StudentHeader assignment={data.assignment} />
          <AssignmentToggleDetails description={data.assignment.description} />
          <StudentContentTabs />
        </div>
      )
    }}
  </Query>
)

StudentView.propTypes = {
  assignmentLid: string.isRequired
}

export default React.memo(StudentView)

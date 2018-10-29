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
import { bool, shape, string } from 'prop-types'
import { graphql } from 'react-apollo'
import gql from 'graphql-tag'

import { AssignmentShape } from '../shared/shapes'
import AssignmentHeader from '../shared/AssignmentHeader'
import ContentTabs from './ContentTabs'

export class CoreTeacherView extends React.Component {
  static propTypes = {
    data: shape({
      assignment: AssignmentShape,
      loading: bool,
      error: string,
    }).isRequired,
  }

  renderError (error) {
    return <div>Error: {error}</div>
  }

  renderLoading () {
    return <div>Loading...</div>
  }

  render () {
    const {data: {assignment, loading, error}} = this.props
    if (error) return this.renderError(error)
    else if (loading) return this.renderLoading()

    return <div>
      Assignments 2 Teacher View
      <AssignmentHeader assignment={assignment} />
      <ContentTabs assignment={assignment} />
    </div>
  }
}

const TeacherQuery = gql`
query GetAssignment($assignmentLid: ID!) {
  assignment: legacyNode(type: Assignment, _id: $assignmentLid) {
    ... on Assignment {
      lid: _id
      gid: id
      name
      description
      dueAt
      pointsPossible
    }
  }
}
`

const TeacherView = graphql(TeacherQuery, {
  options: ({assignmentLid}) => ({
    variables: {
      assignmentLid,
    }
  })
})(CoreTeacherView)

TeacherView.propTypes = Object.assign({
  assignmentLid: string.isRequired,
}, TeacherView.propTypes)

export default TeacherView

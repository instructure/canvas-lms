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
import CommentsContainer from './CommentsContainer'
import {Query} from 'react-apollo'
import {SUBMISSION_COMMENT_QUERY, StudentAssignmentShape} from '../../assignmentData'
import LoadingIndicator from '../LoadingIndicator'

function Comments(props) {
  return (
    <Query
      query={SUBMISSION_COMMENT_QUERY}
      variables={{submissionId: props.assignment.submissionsConnection.nodes[0].id.toString()}}
    >
      {({loading, error, data}) => {
        // TODO HANDLE ERROR
        if (loading) return <LoadingIndicator />
        if (error) return `Error!: ${error}`
        return (
          <div data-testid="comments-container">
            <CommentsContainer comments={data.submissionComments.commentsConnection.nodes} />
          </div>
        )
      }}
    </Query>
  )
}

Comments.propTypes = {
  assignment: StudentAssignmentShape
}

export default React.memo(Comments)

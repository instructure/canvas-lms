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
import {Assignment} from '../../graphqlData/Assignment'
import CommentContent from './CommentContent'
import CommentTextArea from './CommentTextArea'
import ErrorBoundary from '../../../../shared/components/ErrorBoundary'
import errorShipUrl from 'jsx/shared/svg/ErrorShip.svg'
import GenericErrorPage from '../../../../shared/components/GenericErrorPage/index'
import LoadingIndicator from '../../../shared/LoadingIndicator'
import {Query} from 'react-apollo'
import React from 'react'
import {SUBMISSION_COMMENT_QUERY} from '../../graphqlData/Queries'
import {Submission} from '../../graphqlData/Submission'

function CommentsTab(props) {
  const queryVariables = {
    submissionId: props.submission.id,
    submissionAttempt: props.submission.attempt
  }
  // Using the key prop on the query as a work around to these issues:
  // https://github.com/apollographql/react-apollo/issues/2202
  // https://github.com/apollographql/apollo-client/issues/1186
  return (
    <Query
      query={SUBMISSION_COMMENT_QUERY}
      variables={queryVariables}
      key={props.submission.attempt}
    >
      {({loading, error, data}) => {
        if (loading) return <LoadingIndicator />
        if (error) {
          return (
            <GenericErrorPage
              imageUrl={errorShipUrl}
              errorSubject="Assignments 2 Student initial query error"
              errorCategory="Assignments 2 Student Error Page"
            />
          )
        }
        return (
          <ErrorBoundary
            errorComponent={
              <GenericErrorPage
                imageUrl={errorShipUrl}
                errorCategory="Assignments 2 Student Comment Error Page"
              />
            }
          >
            <div data-testid="comments-container">
              <CommentTextArea assignment={props.assignment} submission={props.submission} />
              <CommentContent
                comments={data.submissionComments.commentsConnection.nodes}
                submission={props.submission}
              />
            </div>
          </ErrorBoundary>
        )
      }}
    </Query>
  )
}

CommentsTab.propTypes = {
  assignment: Assignment.shape,
  submission: Submission.shape
}

export default React.memo(CommentsTab)

/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {Assignment} from '@canvas/assignments/graphql/student/Assignment'
import CommentContent from './CommentContent'
import CommentTextArea from './CommentTextArea'
import ErrorBoundary from '@canvas/error-boundary'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import GenericErrorPage from '@canvas/generic-error-page'
import I18n from 'i18n!assignments_2'
import LoadingIndicator from '@canvas/loading-indicator'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-layout'
import React, {useContext, useState} from 'react'
import StudentViewContext from '../Context'
import {SUBMISSION_COMMENT_QUERY} from '@canvas/assignments/graphql/student/Queries'
import {Submission} from '@canvas/assignments/graphql/student/Submission'
import {useQuery} from 'react-apollo'

export default function CommentsTrayBody(props) {
  const [isFetchingMoreComments, setIsFetchingMoreComments] = useState(false)

  const queryVariables = {
    submissionId: props.submission.id,
    submissionAttempt: props.submission.attempt
  }

  const {loading, error, data, fetchMore} = useQuery(SUBMISSION_COMMENT_QUERY, {
    variables: queryVariables
  })

  const loadMoreComments = async () => {
    setIsFetchingMoreComments(true)
    await fetchMore({
      variables: {
        cursor: data.submissionComments.commentsConnection.pageInfo.startCursor,
        ...queryVariables
      },
      updateQuery: (previousResult, {fetchMoreResult}) => {
        const newNodes = fetchMoreResult.submissionComments.commentsConnection.nodes
        const newPageInfo = fetchMoreResult.submissionComments.commentsConnection.pageInfo
        const results = JSON.parse(JSON.stringify(previousResult))
        results.submissionComments.commentsConnection.pageInfo = newPageInfo

        if (newNodes.length) {
          results.submissionComments.commentsConnection.nodes.push(...newNodes)
        }
        return results
      }
    })
    setIsFetchingMoreComments(false)
  }

  const {allowChangesToSubmission} = useContext(StudentViewContext)

  if (loading) return <LoadingIndicator />
  if (error) {
    return (
      <GenericErrorPage
        imageUrl={errorShipUrl}
        errorSubject="Assignments 2 Student submission comments query error"
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
      <Flex as="div" direction="column" height="100%" data-testid="comments-container">
        <Flex.Item grow>
          <div className="load-more-comments-button-container">
            {isFetchingMoreComments && <LoadingIndicator />}
            {data.submissionComments.commentsConnection.pageInfo.hasPreviousPage &&
              !isFetchingMoreComments && (
                <Button variant="primary" onClick={loadMoreComments}>
                  {I18n.t('Load Previous Comments')}
                </Button>
              )}
          </div>
          <CommentContent
            comments={data.submissionComments.commentsConnection.nodes}
            submission={props.submission}
          />
        </Flex.Item>

        {allowChangesToSubmission && (
          <Flex.Item padding="x-small medium">
            <CommentTextArea assignment={props.assignment} submission={props.submission} />
          </Flex.Item>
        )}
      </Flex>
    </ErrorBoundary>
  )
}

CommentsTrayBody.propTypes = {
  assignment: Assignment.shape.isRequired,
  submission: Submission.shape.isRequired
}

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

import AssignmentAlert from './AssignmentAlert'
import I18n from 'i18n!assignments_2_submission_histories_query'
import {InitialQueryShape, SUBMISSION_HISTORIES_QUERY} from '../assignmentData'
import {Query} from 'react-apollo'
import React from 'react'
import ViewManager from './ViewManager'

class SubmissionHistoriesQuery extends React.Component {
  static propTypes = {
    initialQueryData: InitialQueryShape
  }

  state = {
    skipLoadingHistories: true
  }

  getSubmission = () => {
    const submissionsConnection = this.props.initialQueryData.assignment.submissionsConnection
    if (submissionsConnection && submissionsConnection.nodes.length) {
      return submissionsConnection.nodes[0]
    } else {
      return null
    }
  }

  generateOnLoadMore = ({data, error, loading, fetchMore}) => {
    const submission = this.getSubmission()

    // Case 1: There are no submissions histories to load
    if (!submission || submission.attempt <= 1) {
      return () => {}
    }

    // Case 2: We are already waiting for some data to finish loading, or there
    //         was an error loading more data
    if (loading || error) {
      return () => {}
    }

    // Case 3: We haven't loaded any submission histories yet
    if (this.state.skipLoadingHistories === true) {
      return () => this.setState({skipLoadingHistories: false})
    }

    // Case 4: We have loaded some histories but not exhausted pagination
    const pageInfo = data.node.submissionHistoriesConnection.pageInfo
    if (pageInfo.hasPreviousPage) {
      return () =>
        fetchMore({
          variables: {cursor: pageInfo.startCursor, submissionID: submission.id},
          updateQuery: (previousResult, {fetchMoreResult}) => {
            const newNodes = fetchMoreResult.node.submissionHistoriesConnection.nodes
            const newPageInfo = fetchMoreResult.node.submissionHistoriesConnection.pageInfo

            const nextResult = JSON.parse(JSON.stringify(previousResult))
            nextResult.node.submissionHistoriesConnection.pageInfo = newPageInfo
            nextResult.node.submissionHistoriesConnection.nodes = [
              ...newNodes,
              ...nextResult.node.submissionHistoriesConnection.nodes
            ]
            return nextResult
          }
        })
    }

    // Case 5: We have loaded all histories
    return () => {}
  }

  render() {
    const submission = this.getSubmission()
    return (
      <Query
        query={SUBMISSION_HISTORIES_QUERY}
        variables={{submissionID: submission.id}}
        skip={!submission || this.state.skipLoadingHistories}
      >
        {queryResults => {
          const {data, error, loading} = queryResults
          return (
            <React.Fragment>
              {error && (
                <AssignmentAlert errorMessage={I18n.t('Failed to laod more submissions')} />
              )}
              <ViewManager
                initialQueryData={this.props.initialQueryData}
                submissionHistoriesQueryData={loading ? null : data}
                loadMoreSubmissionHistories={this.generateOnLoadMore(queryResults)}
              />
            </React.Fragment>
          )
        }}
      </Query>
    )
  }
}

export default SubmissionHistoriesQuery

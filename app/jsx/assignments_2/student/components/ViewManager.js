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

import {func} from 'prop-types'
import {
  GetAssignmentEnvVariables,
  InitialQueryShape,
  SubmissionHistoriesQueryShape
} from '../assignmentData'
import React from 'react'
import StudentContent from './StudentContent'
import StudentViewContext from './Context'

/* Some helper functions for parsing various graphql query results */

function getInitialSubmission(initialQueryData) {
  const submissionsConnection = initialQueryData.assignment.submissionsConnection
  if (!submissionsConnection || submissionsConnection.nodes.length === 0) {
    return null
  }
  return submissionsConnection.nodes[0]
}

function getSubmissionHistories(submissionHistoriesQueryData) {
  if (!submissionHistoriesQueryData) {
    return []
  }

  const historiesConnection = submissionHistoriesQueryData.node.submissionHistoriesConnection
  if (historiesConnection && historiesConnection.nodes) {
    return historiesConnection.nodes
  } else {
    return []
  }
}

function getAllSubmissions({initialQueryData, submissionHistoriesQueryData}) {
  const initialSubmission = getInitialSubmission(initialQueryData)
  if (!initialSubmission) {
    return []
  }

  // submisison histories don't have an id. We are going to add the initial
  // submissions id to all of the histories that we can query submission
  // comments without having to pipe both the initial submission and
  // currently displayed submission to all components.
  const submissionHistories = getSubmissionHistories(submissionHistoriesQueryData).map(history => {
    return {...history, id: initialSubmission.id}
  })
  submissionHistories.push(initialSubmission)
  return submissionHistories
}

/* End helper functions for parsing graphql query results */

class ViewManager extends React.Component {
  static propTypes = {
    initialQueryData: InitialQueryShape,
    loadMoreSubmissionHistories: func,
    // eslint-disable-next-line react/no-unused-prop-types
    submissionHistoriesQueryData: SubmissionHistoriesQueryShape
  }

  state = {
    submissions: [],
    displayedAttempt: null, // eslint-disable-line react/no-unused-state
    loadingMore: false
  }

  static getDerivedStateFromProps(props, state) {
    const oldAllSubmissions = state.submissions
    const newAllSubmissions = getAllSubmissions(props)

    // Case where there are no submissions (user not logged in on public course)
    if (oldAllSubmissions.length === 0 && newAllSubmissions.length === 0) {
      return null
    }

    // Case where we have new submission histories coming in
    if (newAllSubmissions.length > oldAllSubmissions.length) {
      const newDisplayIndex = newAllSubmissions.length - oldAllSubmissions.length - 1
      return {
        submissions: newAllSubmissions,
        displayedAttempt: newAllSubmissions[newDisplayIndex].attempt,
        loadingMore: false
      }
    }

    // Case where the current submission is new
    const oldSubmission = oldAllSubmissions[oldAllSubmissions.length - 1]
    const newSubmission = newAllSubmissions[newAllSubmissions.length - 1]
    if (oldSubmission.attempt !== newSubmission.attempt) {
      return {
        submissions: newAllSubmissions,
        displayedAttempt: newSubmission.attempt
      }
    }

    return {
      submissions: newAllSubmissions
    }
  }

  getAssignmentWithEnv = () => {
    const assignment = this.props.initialQueryData.assignment
    const assignmentCopy = JSON.parse(JSON.stringify(assignment))
    delete assignmentCopy.submissionsConnection
    assignmentCopy.env = GetAssignmentEnvVariables()
    return assignmentCopy
  }

  getPageInfo = (opts = {}) => {
    const props = opts.props || this.props
    if (!props.submissionHistoriesQueryData) {
      return null
    }

    const historiesConnection =
      props.submissionHistoriesQueryData.node.submissionHistoriesConnection
    return historiesConnection && historiesConnection.pageInfo
  }

  getDisplayedSubmissionIndex = (opts = {}) => {
    const state = opts.state || this.state
    return state.submissions.findIndex(s => s.attempt === state.displayedAttempt)
  }

  getDisplayedSubmission = (opts = {}) => {
    const state = opts.state || this.state
    return state.submissions[this.getDisplayedSubmissionIndex(opts)]
  }

  hasNextSubmission = (opts = {}) => {
    const state = opts.state || this.state
    const currentIndex = this.getDisplayedSubmissionIndex(opts)
    return currentIndex !== state.submissions.length - 1
  }

  hasPrevSubmission = (opts = {}) => {
    const state = opts.state || this.state

    // If we haven't loaded any histories yet (and aren't on attempt 1), or if
    // we still have more histories to load
    const pageInfo = this.getPageInfo(opts)
    if (!pageInfo && state.displayedAttempt > 1) {
      return true
    } else if (pageInfo && pageInfo.hasPreviousPage) {
      return true
    }

    const currentIndex = this.getDisplayedSubmissionIndex(opts)
    return currentIndex !== 0
  }

  onNextSubmission = () => {
    this.setState((state, props) => {
      const opts = {state, props}
      if (!this.hasNextSubmission(opts)) {
        return null
      }

      const currentIndex = this.getDisplayedSubmissionIndex(opts)
      const nextAttempt = state.submissions[currentIndex + 1].attempt
      return {displayedAttempt: nextAttempt}
    })
  }

  onPrevSubmission = () => {
    this.setState((state, props) => {
      const opts = {state, props}

      // If we are already loading more submissions histories, we cannot go back
      // any further until the graphql query is complete
      if (state.loadingMore || !this.hasPrevSubmission(opts)) {
        return null
      }

      const currentIndex = this.getDisplayedSubmissionIndex(opts)
      if (currentIndex === 0) {
        props.loadMoreSubmissionHistories()
        return {loadingMore: true}
      } else {
        return {displayedAttempt: state.submissions[currentIndex - 1].attempt}
      }
    })
  }

  render() {
    const assignment = this.getAssignmentWithEnv()
    const submission = this.getDisplayedSubmission()

    return (
      <StudentViewContext.Provider
        value={{
          prevButtonEnabled: this.hasPrevSubmission(),
          nextButtonEnabled: this.hasNextSubmission(),
          prevButtonAction: this.onPrevSubmission,
          nextButtonAction: this.onNextSubmission,
          latestSubmission: getInitialSubmission(this.props.initialQueryData)
        }}
      >
        <StudentContent assignment={assignment} submission={submission} />
      </StudentViewContext.Provider>
    )
  }
}

export default ViewManager

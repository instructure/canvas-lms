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

import {arrayOf, shape} from 'prop-types'
import {
  Assignment,
  AssignmentSubmissionsConnection,
} from '@canvas/assignments/graphql/student/Assignment'
import React from 'react'
import StudentContent from './StudentContent'
import StudentViewContext from './Context'
import {Submission} from '@canvas/assignments/graphql/student/Submission'

// Helper functions used by this component

function makeDummyNextSubmission(submission) {
  return {
    ...submission,
    attachments: [],
    attempt: submission.attempt + 1,
    deductedPoints: null,
    enteredGrade: null,
    feedbackForCurrentAttempt: submission.attempt === 0 && submission.feedbackForCurrentAttempt,
    grade: null,
    gradingStatus: null,
    latePolicyStatus: null,
    state: 'unsubmitted',
    submissionDraft: submission.submissionDraft,
    submissionStatus: 'unsubmitted',
    submittedAt: null,
    unreadCommentCount: 0,
  }
}

function getSubmissionHistories(submissionHistoriesQueryData) {
  if (!submissionHistoriesQueryData) {
    return []
  }

  const historiesConnection = submissionHistoriesQueryData.node.submissionHistoriesConnection
  return historiesConnection?.nodes || []
}

function getAllSubmissions({initialQueryData, submissionHistoriesQueryData}) {
  const initialSubmission = initialQueryData.submission
  if (!initialSubmission) {
    return []
  }

  // submission histories don't have an id. We are going to add the initial
  // submissions id to all of the histories that we can query submission
  // comments without having to pipe both the initial submission and
  // currently displayed submission to all components.
  const submissionHistories = getSubmissionHistories(submissionHistoriesQueryData).map(history => {
    return {...history, _id: initialSubmission._id, id: initialSubmission.id}
  })
  submissionHistories.push(initialSubmission)
  return submissionHistories
}

class ViewManager extends React.Component {
  static propTypes = {
    initialQueryData: shape({
      ...Assignment.shape.propTypes,
      ...AssignmentSubmissionsConnection.shape.propTypes,
    }),
    // eslint-disable-next-line react/no-unused-prop-types
    submissionHistoriesQueryData: shape({
      submissionHistoriesConnection: shape({
        nodes: arrayOf(Submission.shape),
      }),
    }),
  }

  state = {
    displayedAttempt: null,
    dummyNextSubmission: null,
    submissions: [],
    reviewerSubmission: [],
  }

  static getDerivedStateFromProps(props, state) {
    const prevState = state
    const nextState = {
      ...prevState,
      submissions: getAllSubmissions(props),
    }

    // Case where there are no submissions (user not logged in on public course)
    if (prevState.submissions.length === 0 && nextState.submissions.length === 0) {
      return nextState
    }

    // A submission draft for attempt n+1 is tied to the lastest submitted submission
    // with attempt n (thanks versionable). All of our children already know how to
    // display a submission draft for an unsubmitted assignment, because that's how the
    // attempt 0 works. Rather then making the components aware of how to toggle back
    // and forth and display a submission draft for an already submitted submission,
    // we are moving the submission draft for attempt n+1 into an unsubmitted
    // "dummy submission" that all our components already know how to handle.
    let currentSubmission = nextState.submissions[nextState.submissions.length - 1]
    if (currentSubmission.submissionDraft) {
      nextState.submissions.push(makeDummyNextSubmission(currentSubmission))
      nextState.dummyNextSubmission = null
    } else if (state.dummyNextSubmission) {
      nextState.submissions.push(state.dummyNextSubmission)
    }
    currentSubmission = nextState.submissions[nextState.submissions.length - 1]

    const prevStateCurrentSubmission = prevState.submissions[prevState.submissions.length - 1] || {}

    if (prevStateCurrentSubmission.attempt !== currentSubmission.attempt) {
      // Case where the "current" submission is new. This could be because an the
      // page was initially loaded, an assignment was submitted, a submission draft
      // was created, or the new attempt button was clicked which triggered a dummy
      // submission to be created.
      nextState.displayedAttempt = currentSubmission.attempt
    }

    return nextState
  }

  getAssignment = () => {
    // Srtip out the submission connections here so our children cannot accidently
    // use that instead of the explict submission we are passing down as a prop
    const assignment = this.props.initialQueryData.assignment
    const assignmentCopy = JSON.parse(JSON.stringify(assignment))
    delete assignmentCopy.submissionsConnection
    return assignmentCopy
  }

  getReviewerSubmission = () => {
    return this.props.initialQueryData.reviewerSubmission
  }

  getPageInfo = (opts = {}) => {
    const props = opts.props || this.props
    if (!props.submissionHistoriesQueryData) {
      return null
    }

    return props.submissionHistoriesQueryData.node.submissionHistoriesConnection?.pageInfo
  }

  getDisplayedSubmissionIndex = (opts = {}) => {
    const state = opts.state || this.state
    const index = state.submissions.findIndex(s => s.attempt === state.displayedAttempt)
    if (index === -1) {
      throw new Error('Could not find displayed submission')
    }
    return index
  }

  getDisplayedSubmission = (opts = {}) => {
    const state = opts.state || this.state
    return state.submissions[this.getDisplayedSubmissionIndex(opts)]
  }

  getLatestSubmission = (opts = {}) => {
    const state = opts.state || this.state
    return state.submissions[state.submissions.length - 1]
  }

  hasNextSubmission = (opts = {}) => {
    const state = opts.state || this.state
    const currentIndex = this.getDisplayedSubmissionIndex(opts)
    return currentIndex !== state.submissions.length - 1
  }

  onChangeSubmission = attempt => {
    this.setState({displayedAttempt: attempt})
  }

  onStartNewAttempt = () => {
    this.setState(
      (state, props) => {
        const opts = {state, props}
        const submission = this.getDisplayedSubmission(opts)

        // Can only create a new dummy submission if a dummy doesn't already
        // exist, either because this was already called or because it was
        // created for a submission draft.
        if (state.dummyNextSubmission || submission.submissionDraft) {
          return null
        }

        // This dummy submission isn't backed by a submission draft in the database
        // at this point. Until the user does something like uploading a file which
        // creates a real submission draft, this will exist only on the frontend,
        // which is why we need to save it to the state so isn't forgotten about.
        // Once the user does make a frd submission draft, the dummy submission in
        // the state will be set back to null, and a new dummy submission will be
        // created from that submission draft instead. See getDerivedStateFromProps.
        const dummyNextSubmission = makeDummyNextSubmission(this.getLatestSubmission(opts))
        return {
          dummyNextSubmission,
          displayedAttempt: dummyNextSubmission.attempt,
        }
      },
      () => {
        document
          .querySelector('button[data-testid=assignments-2-assignment-toggle-details]')
          .focus()
      }
    )
  }

  onCancelDraft = () => {
    // If we cancelled a draft consisting only of a dummy submission, we need
    // to note its deletion. If the draft had actual content, the mutation
    // handles updating the list of submissions.
    this.setState((oldState, _props) => {
      const {submissions} = oldState

      if (oldState.dummyNextSubmission == null) {
        return
      }

      return {
        displayedAttempt: submissions[submissions.length - 1].attempt,
        dummyNextSubmission: null,
      }
    })
  }

  render() {
    const assignment = this.getAssignment()
    const submission = this.getDisplayedSubmission()
    const reviewerSubmission = this.getReviewerSubmission()

    return (
      <StudentViewContext.Provider
        value={{
          allowChangesToSubmission:
            ENV.enrollment_state === 'active' &&
            !ENV.ISOBSERVER &&
            submission.gradingStatus !== 'excused',
          cancelDraftAction: this.onCancelDraft,
          isLatestAttempt: !this.hasNextSubmission(),
          latestSubmission: this.getLatestSubmission(),
          lastSubmittedSubmission: this.props.initialQueryData.submission,
          isObserver: ENV.ISOBSERVER,
          showDraftAction: () => {
            this.onChangeSubmission(this.getLatestSubmission().attempt)
          },
          startNewAttemptAction: this.onStartNewAttempt,
        }}
      >
        <StudentContent
          assignment={assignment}
          submission={submission}
          reviewerSubmission={reviewerSubmission}
          allSubmissions={this.state.submissions}
          onChangeSubmission={this.onChangeSubmission}
        />
      </StudentViewContext.Provider>
    )
  }
}

export default ViewManager

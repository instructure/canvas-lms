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
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {Assignment} from '@canvas/assignments/graphql/student/Assignment'
import AssignmentToggleDetails from '../AssignmentToggleDetails'
import {useScope as useI18nScope} from '@canvas/i18n'
import Header from './Header'
import {Query} from 'react-apollo'
import React, {Suspense, lazy} from 'react'
import {shape} from 'prop-types'
import {Spinner} from '@instructure/ui-spinner'
import {Submission} from '@canvas/assignments/graphql/student/Submission'
import {SUBMISSION_HISTORIES_QUERY} from '@canvas/assignments/graphql/student/Queries'
import ViewManager from './ViewManager'
import UnavailablePeerReview from '../UnavailablePeerReview'
import NeedsSubmissionPeerReview from '../NeedsSubmissionPeerReview'

const I18n = useI18nScope('assignments_2_submission_histories_query')

const LoggedOutTabs = lazy(() => import('./LoggedOutTabs'))

function shouldDisplayNeedsSubmissionPeerReview({assignment, reviewerSubmission}) {
  return assignment.env.peerReviewModeEnabled && reviewerSubmission?.state === 'unsubmitted'
}

function shouldDisplayUnavailablePeerReview({assignment, reviewerSubmission}) {
  return (
    reviewerSubmission !== null &&
    assignment.env.peerReviewModeEnabled &&
    !assignment.env.peerReviewAvailable
  )
}

// eslint-disable-next-line react/prefer-stateless-function
class SubmissionHistoriesQuery extends React.Component {
  static propTypes = {
    initialQueryData: shape({
      ...Assignment.shape.propTypes,
      ...Submission.shape.propTypes,
    }),
  }

  render() {
    const {submission} = this.props.initialQueryData

    if (shouldDisplayNeedsSubmissionPeerReview(this.props.initialQueryData)) {
      return (
        <>
          <Header
            scrollThreshold={150}
            assignment={this.props.initialQueryData.assignment}
            peerReviewLinkData={this.props.initialQueryData.reviewerSubmission}
          />
          <AssignmentToggleDetails
            description={this.props.initialQueryData.assignment.description}
          />
          <NeedsSubmissionPeerReview />
        </>
      )
    }

    if (shouldDisplayUnavailablePeerReview(this.props.initialQueryData)) {
      return (
        <>
          <Header
            scrollThreshold={150}
            assignment={this.props.initialQueryData.assignment}
            peerReviewLinkData={this.props.initialQueryData.reviewerSubmission}
          />
          <AssignmentToggleDetails
            description={this.props.initialQueryData.assignment.description}
          />
          <UnavailablePeerReview />
        </>
      )
    }

    if (!submission) {
      // User hasn't accepted course invite
      return (
        <>
          <Header scrollThreshold={150} assignment={this.props.initialQueryData.assignment} />
          <AssignmentToggleDetails
            description={this.props.initialQueryData.assignment.description}
          />
          <Suspense
            fallback={
              <Spinner renderTitle={I18n.t('Loading')} size="large" margin="0 0 0 medium" />
            }
          >
            <LoggedOutTabs
              nonAcceptedEnrollment={true}
              assignment={this.props.initialQueryData.assignment}
            />
          </Suspense>
        </>
      )
    }

    return (
      <Query
        onError={() => this.context.setOnFailure(I18n.t('Failed to load more submissions'))}
        query={SUBMISSION_HISTORIES_QUERY}
        variables={{submissionID: submission.id}}
      >
        {queryResults => {
          const {data, loading} = queryResults
          return (
            <ViewManager
              initialQueryData={this.props.initialQueryData}
              submissionHistoriesQueryData={loading ? null : data}
            />
          )
        }}
      </Query>
    )
  }
}

SubmissionHistoriesQuery.contextType = AlertManagerContext

export default SubmissionHistoriesQuery

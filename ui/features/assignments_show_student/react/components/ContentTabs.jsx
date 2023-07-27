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

import {Assignment} from '@canvas/assignments/graphql/student/Assignment'
import {useScope as useI18nScope} from '@canvas/i18n'

import LoadingIndicator from '@canvas/loading-indicator'
import React, {lazy, Suspense} from 'react'
import SubmissionManager from './SubmissionManager'
import {Submission} from '@canvas/assignments/graphql/student/Submission'
import {Tabs} from '@instructure/ui-tabs'
import {View} from '@instructure/ui-view'
import PropTypes from 'prop-types'

const I18n = useI18nScope('assignments_2')

const RubricTab = lazy(() =>
  import(
    /* webpackChunkName: "RubricTab" */
    /* webpackPrefetch: true */
    './RubricTab'
  )
)

ContentTabs.propTypes = {
  assignment: Assignment.shape,
  submission: Submission.shape,
  reviewerSubmission: Submission.shape,
  onSuccessfulPeerReview: PropTypes.func,
}

function LoggedInContentTabs(props) {
  const noRightLeftPadding = 'small none' // to make "submit" button edge line up with moduleSequenceFooter "next" button edge

  return (
    <div data-testid="assignment-2-student-content-tabs">
      <View padding={noRightLeftPadding}>
        <SubmissionManager
          assignment={props.assignment}
          submission={props.submission}
          reviewerSubmission={props.reviewerSubmission}
          onSuccessfulPeerReview={props.onSuccessfulPeerReview}
        />
      </View>
    </div>
  )
}

// FIXME: this may not actually be used now that we fixed the triple-equals
function LoggedOutContentTabs(props) {
  // Note that for not logged in users we already have the rubrics data available
  // on the assignment, and don't need to do a seperate query to get that data.
  // This is to avoid a large time watching loading spinners on the default tab
  // which we want to render as fast as possible.
  return (
    <div data-testid="assignment-2-student-content-tabs">
      {props.assignment.rubric && (
        <Tabs variant="default">
          <Tabs.Panel renderTitle={I18n.t('Rubric')} isSelected={true}>
            <Suspense fallback={<LoadingIndicator />}>
              <RubricTab rubric={props.assignment.rubric} />
            </Suspense>
          </Tabs.Panel>
        </Tabs>
      )}
    </div>
  )
}

export default function ContentTabs(props) {
  if (props.submission) {
    return <LoggedInContentTabs {...props} />
  } else {
    return <LoggedOutContentTabs {...props} />
  }
}

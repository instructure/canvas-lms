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

import AlertManager from '@canvas/alerts/react/AlertManager'
import {ApolloProvider, createClient} from '@canvas/apollo'
import ErrorBoundary from '@canvas/error-boundary'
import {useScope as useI18nScope} from '@canvas/i18n'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import GenericErrorPage from '@canvas/generic-error-page'
import ObserverOptions from '@canvas/observer-picker'
import {
  getHandleChangeObservedUser,
  autoFocusObserverPicker,
} from '@canvas/observer-picker/util/pageReloadHelper'
import React from 'react'
import ReactDOM from 'react-dom'
import StudentViewQuery from './components/StudentViewQuery'
import {View} from '@instructure/ui-view'

const client = createClient()
const I18n = useI18nScope('assignments_2')

export default function renderAssignmentsApp(env, elt) {
  ReactDOM.render(
    <ApolloProvider client={client}>
      <ErrorBoundary
        errorComponent={
          <GenericErrorPage
            imageUrl={errorShipUrl}
            errorCategory="Assignments 2 Student Error Page"
          />
        }
      >
        <AlertManager>
          <StudentViewQuery
            assignmentLid={ENV.ASSIGNMENT_ID.toString()}
            submissionID={ENV.SUBMISSION_ID?.toString()}
            reviewerSubmissionID={ENV.REVIEWER_SUBMISSION_ID?.toString()}
          />
        </AlertManager>
      </ErrorBoundary>
    </ApolloProvider>,
    elt
  )

  const observerPickerContainer = document.getElementById('observer-picker-mountpoint')
  if (observerPickerContainer && ENV.OBSERVER_OPTIONS?.OBSERVED_USERS_LIST) {
    ReactDOM.render(
      <View as="div" maxWidth="12em">
        <ObserverOptions
          autoFocus={autoFocusObserverPicker()}
          canAddObservee={!!ENV.OBSERVER_OPTIONS?.CAN_ADD_OBSERVEE}
          currentUserRoles={ENV.current_user_roles}
          currentUser={ENV.current_user}
          handleChangeObservedUser={getHandleChangeObservedUser()}
          observedUsersList={ENV.OBSERVER_OPTIONS.OBSERVED_USERS_LIST}
          renderLabel={I18n.t('Select a student to view. The page will refresh automatically.')}
        />
      </View>,
      observerPickerContainer
    )
  }
}

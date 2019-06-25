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

import errorShipUrl from '../SVG/ErrorShip.svg'
import GenericErrorPage from '../../../shared/components/GenericErrorPage/index'
import I18n from 'i18n!assignments_2_initial_query'
import {InitialQueryShape, SUBMISSION_ATTACHMENTS_QUERY} from '../assignmentData'
import {Query} from 'react-apollo'
import React from 'react'
import SubmissionHistoriesQuery from './SubmissionHistoriesQuery'

const InitialAttachmentsQuery = props => {
  return (
    <Query
      query={SUBMISSION_ATTACHMENTS_QUERY}
      variables={{
        submissionID: props.initialQueryData.assignment.submissionsConnection.nodes[0].id
      }}
    >
      {({loading, error, data}) => {
        if (error) {
          return (
            <GenericErrorPage
              imageUrl={errorShipUrl}
              errorSubject={I18n.t('Assignments 2 Student submission preview query error')}
              errorCategory={I18n.t('Assignments 2 Student Error Page')}
            />
          )
        }

        if (!loading && data) {
          props.initialQueryData.assignment.submissionsConnection.nodes[0].attachments =
            data.submission.attachments
        }

        return <SubmissionHistoriesQuery initialQueryData={props.initialQueryData} />
      }}
    </Query>
  )
}

InitialAttachmentsQuery.propTypes = {
  initialQueryData: InitialQueryShape
}

export default InitialAttachmentsQuery

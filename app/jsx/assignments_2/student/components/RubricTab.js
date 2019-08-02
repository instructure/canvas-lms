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

import {Assignment} from '../graphqlData/Assignment'
import errorShipUrl from '../SVG/ErrorShip.svg'
import GenericErrorPage from '../../../shared/components/GenericErrorPage/index'
import I18n from 'i18n!assignments_2'
import LoadingIndicator from '../../shared/LoadingIndicator'
import {Query} from 'react-apollo'
import React from 'react'
import Rubric from '../../../rubrics/Rubric'
import {RUBRIC_QUERY} from '../graphqlData/Queries'

// TODO: Currently, there is no difference between rubrics for ungraded
// and graded assignments. This will change in the near future.
function RubricTab(props) {
  return (
    <Query query={RUBRIC_QUERY} variables={{assignmentID: props.assignment._id}}>
      {({loading, error, data}) => {
        if (loading) return <LoadingIndicator />
        if (error) {
          return (
            <GenericErrorPage
              imageUrl={errorShipUrl}
              errorSubject={I18n.t('Assignments 2 Student initial query error')}
              errorCategory={I18n.t('Assignments 2 Student Error Page')}
            />
          )
        }
        return <Rubric rubric={data.assignment.rubric} />
      }}
    </Query>
  )
}

RubricTab.propTypes = {
  assignment: Assignment.shape
}

export default React.memo(RubricTab)

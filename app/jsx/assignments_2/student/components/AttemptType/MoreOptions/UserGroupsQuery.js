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

import {arrayOf, bool, func, string} from 'prop-types'
import errorShipUrl from 'jsx/shared/svg/ErrorShip.svg'
import {ExternalTool} from '../../../graphqlData/ExternalTool'
import GenericErrorPage from '../../../../../shared/components/GenericErrorPage/index'
import I18n from 'i18n!assignments_2_initial_query'
import LoadingIndicator from 'jsx/shared/LoadingIndicator'
import {useQuery} from 'react-apollo'
import React from 'react'
import Tools from './Tools'
import {USER_GROUPS_QUERY} from '../../../graphqlData/Queries'

const UserGroupsQuery = props => {
  const {loading, error, data} = useQuery(USER_GROUPS_QUERY, {
    variables: {userID: props.userID},
    skip: !props.renderCanvasFiles
  })

  if (loading) return <LoadingIndicator />
  if (error) {
    return (
      <GenericErrorPage
        imageUrl={errorShipUrl}
        errorSubject={I18n.t('User groups query error')}
        errorCategory={I18n.t('Assignments 2 Student Error Page')}
      />
    )
  }
  const groups = props.renderCanvasFiles ? data.legacyNode : null

  return (
    <Tools
      assignmentID={props.assignmentID}
      courseID={props.courseID}
      handleCanvasFileSelect={props.handleCanvasFileSelect}
      renderCanvasFiles={props.renderCanvasFiles}
      tools={props.tools}
      userGroups={groups}
    />
  )
}
UserGroupsQuery.propTypes = {
  assignmentID: string.isRequired,
  courseID: string.isRequired,
  handleCanvasFileSelect: func,
  renderCanvasFiles: bool,
  tools: arrayOf(ExternalTool.shape),
  userID: string
}

export default UserGroupsQuery

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

import React from 'react'
import StudentContent from './components/StudentContent'
import {string} from 'prop-types'
import {Query} from 'react-apollo'
import {STUDENT_VIEW_QUERY} from './assignmentData'

const StudentView = props => (
  <Query query={STUDENT_VIEW_QUERY} variables={{assignmentLid: props.assignmentLid}}>
    {({loading, error, data}) => {
      // TODO HANDLE ERROR AND LOADING
      if (loading) return null
      if (error) return `Error!: ${error}`
      document.title = data.assignment.name
      return <StudentContent assignment={data.assignment} />
    }}
  </Query>
)

StudentView.propTypes = {
  assignmentLid: string.isRequired
}

export default React.memo(StudentView)

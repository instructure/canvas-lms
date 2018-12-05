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

import {StudentAssignmentShape} from '../assignmentData'
import Header from './Header'
import AssignmentToggleDetails from '../../shared/AssignmentToggleDetails'
import ContentTabs from './ContentTabs'
import MissingPrereqs from './MissingPrereqs'
import LockedAssignment from './LockedAssignment'

function renderContentBaseOnAvailability(assignment) {
  // TODO get this from graphql instead of ENV
  if (ENV && ENV.PREREQS && ENV.PREREQS.items && ENV.PREREQS.items.length !== 0) {
    const preReqItem = ENV.PREREQS.items[0] && ENV.PREREQS.items[0].prev
    return <MissingPrereqs preReqTitle={preReqItem.title} preReqLink={preReqItem.html_url} />
  } else if (assignment && assignment.lockInfo.isLocked) {
    return <LockedAssignment assignment={assignment} />
  } else {
    return (
      <React.Fragment>
        <AssignmentToggleDetails description={assignment && assignment.description} />
        <ContentTabs />
      </React.Fragment>
    )
  }
}

function StudentContent(props) {
  const {assignment} = props
  return (
    <div data-test-id="assignments-2-student-view">
      <Header assignment={assignment} />
      {renderContentBaseOnAvailability(assignment)}
    </div>
  )
}

StudentContent.propTypes = {
  assignment: StudentAssignmentShape
}

export default React.memo(StudentContent)

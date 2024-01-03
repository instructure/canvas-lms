/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {
  type AssignmentPeerReview,
  StudentViewPeerReviews,
} from '@canvas/student_view_peer_reviews/react/StudentViewPeerReviews'
import ready from '@instructure/ready'
import React from 'react'
import ReactDOM from 'react-dom'
import {getAssignments, formatGraphqlModuleNodes} from './utils/helper'

ready(async () => {
  if (!ENV.course_id || JSON.stringify(ENV.current_user) === '{}') return

  const graphqlModuleItemsNodes = await getAssignments(ENV.course_id.toString())

  if (!graphqlModuleItemsNodes || graphqlModuleItemsNodes.length === 0) return

  const formattedAssginments = formatGraphqlModuleNodes(graphqlModuleItemsNodes)

  formattedAssginments.forEach(([_key, data]) => {
    Object.entries(data).forEach(([_, value]) => {
      ReactDOM.render(
        // @ts-expect-error
        <StudentViewPeerReviews assignment={value.assignment as AssignmentPeerReview} />,
        value.container
      )
    })
  })
})

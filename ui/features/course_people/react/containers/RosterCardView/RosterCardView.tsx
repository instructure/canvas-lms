/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {List} from '@instructure/ui-list'
import RosterCard from '../../components/RosterCard/RosterCard'

interface CourseUserNode {
  _id: string
  name: string
  sisId?: string
  enrollments: Array<{
    id: string
    type: string
    totalActivityTime?: number
    htmlUrl: string
    state: string
    canBeRemoved: boolean
    section?: any
    associatedUser?: any
    [key: string]: any
  }>
  loginId?: string
  avatarUrl?: string
  pronouns?: string
  [key: string]: any
}

interface RosterCardViewProps {
  data: {
    course: {
      usersConnection: {
        nodes: CourseUserNode[]
      }
    }
  }
}

const RosterCardView: React.FC<RosterCardViewProps> = ({data}) => {
  const RosterCards = data.course.usersConnection.nodes.map(node => (
    <List.Item key={node._id}>
      <RosterCard courseUsersConnectionNode={node} />
    </List.Item>
  ))

  return (
    <List isUnstyled={true} margin="0">
      {RosterCards}
    </List>
  )
}

export default RosterCardView

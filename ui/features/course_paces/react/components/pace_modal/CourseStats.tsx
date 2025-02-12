/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import { connect } from 'react-redux'
import { StoreState, PaceContext } from '../../types'
import { Pill } from '@instructure/ui-pill'
import { Flex } from '@instructure/ui-flex'
import { getIsDraftPace, getCoursePaceItems } from '../../reducers/course_paces'

interface CourseStatsProps {
  readonly assignmentsCount: number
  readonly isDraftPace: boolean
  readonly paceContext: PaceContext
}

export const CourseStats = ({
  assignmentsCount,
  isDraftPace,
  paceContext
}: CourseStatsProps) => {
  const StatusElement = ({ title, statValue, dataTestId }: { title: string, statValue: string | number, dataTestId: string }) => {

    return (
      <Flex.Item>
        <Pill statusLabel={title} data-testid={dataTestId}>
          {statValue}
        </Pill>
      </Flex.Item>
    )
  }

  return (
    <Flex gap="small" margin="small none" data-testid="course-stats-info">
      {isDraftPace &&
        <StatusElement title='Status' statValue='Draft' dataTestId='status-draft' />
      }
      <StatusElement title='Student Enrolled' statValue={paceContext?.associated_student_count} dataTestId='student-enrollment-count' />
      <StatusElement title='Assignments Count' statValue={assignmentsCount} dataTestId='assignments-count' />
    </Flex>
  )
}

const mapStateToProps = (state: StoreState) => {
  return {
    assignmentsCount: getCoursePaceItems(state).length,
    isDraftPace: getIsDraftPace(state)
  }
}

export default connect(mapStateToProps)(CourseStats)

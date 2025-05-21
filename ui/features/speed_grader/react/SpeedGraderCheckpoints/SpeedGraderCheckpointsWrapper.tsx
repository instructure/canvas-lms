/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import AlertManager from '@canvas/alerts/react/AlertManager'
import {SpeedGraderCheckpointsContainer} from './SpeedGraderCheckpointsContainer'
import {QueryClientProvider} from '@tanstack/react-query'
import {queryClient} from '@canvas/query'

type SpeedGrader = {
  setOrUpdateSubmission: (submission: any) => any
  updateSelectMenuStatus: (student: any) => any
}

type Props = {
  EG: SpeedGrader
  courseId: string
  assignmentId: string
  studentId: string
}

export const SpeedGraderCheckpointsWrapper = ({EG, courseId, assignmentId, studentId}: Props) => {
  const customGradeStatuses = ENV.custom_grade_statuses || []
  const lateSubmissionInterval = ENV?.late_policy?.late_submission_interval || 'day'

  return (
    <QueryClientProvider client={queryClient}>
      {/* @ts-expect-error */}
      <AlertManager>
        <SpeedGraderCheckpointsContainer
          EG={EG}
          courseId={courseId}
          assignmentId={assignmentId}
          studentId={studentId}
          customGradeStatusesEnabled={customGradeStatuses.length > 0}
          customGradeStatuses={customGradeStatuses}
          lateSubmissionInterval={lateSubmissionInterval}
        />
      </AlertManager>
    </QueryClientProvider>
  )
}

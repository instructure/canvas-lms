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

import {Submission} from '../../../api'

/**
 * SpeedGrader-related INST values. Ideally this would be refactored into speed_grader.tsx.
 *
 * Note that this isn't a partial, so INST can be cast to InstSpeedGrader for non-safe access
 * to properties.
 */
export interface InstSpeedGrader {
  refreshGrades(
    callback: (submission: Submission) => void,
    retry?: (
      submission: Submission,
      originalSubmission: Submission,
      numRequests: number
    ) => boolean,
    retryDelay?: number
  )
  refreshQuizSubmissionSnapshot(data: {user_id: string; version_number: string})
  clearQuizSubmissionSnapshot(data: {user_id: string; version_number: string})
  getQuizSubmissionSnapshot(user_id: string, version_number: string): unknown

  lastQuestionTouched?: unknown
}

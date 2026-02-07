/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import React, {useEffect} from 'react'
import {NewQuizzesApp} from '@canvas/new-quizzes/react/NewQuizzesApp'

interface SpeedGraderNativeQuizRendererProps {
  submission: any // Current submission object
}

// Extract query params from submission URL for dynamic session IDs
function extractQueryParams(url: string | undefined) {
  const params: Record<string, string> = {}

  // Add grade_by_question from launch data params
  if (ENV.NEW_QUIZZES?.grade_by_question_enabled !== undefined) {
    params.grade_by_question_enabled = String(ENV.NEW_QUIZZES.grade_by_question_enabled)
  }

  if (!url) return params

  try {
    const urlObj = new URL(url)

    if (urlObj.searchParams.has('participant_session_id')) {
      params.participant_session_id = urlObj.searchParams.get('participant_session_id')!
    }
    if (urlObj.searchParams.has('quiz_session_id')) {
      params.quiz_session_id = urlObj.searchParams.get('quiz_session_id')!
    }

    return params
  } catch (e) {
    console.error('Failed to parse submission URL:', e)
    return params
  }
}

/**
 * SpeedGrader wrapper around NewQuizzesApp that adds:
 * - Submission tracking via postMessage
 * - Query param extraction from submission URLs
 */
export function SpeedGraderNativeQuizRenderer({submission}: SpeedGraderNativeQuizRendererProps) {
  useEffect(() => {
    if (!submission) return

    const message = {
      subject: 'canvas.speedGraderSubmissionChange',
      submission: {
        ...submission,
        external_tool_url: submission.url,
      },
    }

    window.postMessage(message, '*')
  }, [submission])

  const speedgraderExtensions = {
    queryParams: extractQueryParams(submission?.external_tool_url || submission?.url),
  }

  return <NewQuizzesApp speedgraderExtensions={speedgraderExtensions} />
}

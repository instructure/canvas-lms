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

import {useState, useCallback, useEffect} from 'react'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {ConversationEvaluation} from '../../types'

export const useConversationEvaluation = (
  courseId: string | number,
  aiExperienceId: string | number,
  conversationId?: string,
) => {
  const [evaluation, setEvaluation] = useState<ConversationEvaluation | null>(null)
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  // Reset evaluation when conversation changes
  useEffect(() => {
    setEvaluation(null)
    setError(null)
  }, [conversationId])

  const fetchEvaluation = useCallback(async () => {
    if (!conversationId) return

    setIsLoading(true)
    setError(null)

    try {
      const {json} = await doFetchApi<{evaluation: ConversationEvaluation}>({
        path: `/api/v1/courses/${courseId}/ai_experiences/${aiExperienceId}/conversations/${conversationId}/evaluation`,
      })

      setEvaluation(json?.evaluation ?? null)
    } catch (err) {
      setError((err as Error).message)
    } finally {
      setIsLoading(false)
    }
  }, [courseId, aiExperienceId, conversationId])

  return {evaluation, isLoading, error, fetchEvaluation}
}

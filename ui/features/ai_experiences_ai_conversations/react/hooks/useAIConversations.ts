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

import {useState, useEffect} from 'react'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {StudentConversation, ConversationDetail} from '../../types'

// Hook to fetch all student conversations
export const useStudentConversations = (
  courseId: string | number,
  aiExperienceId: string | number,
) => {
  const [conversations, setConversations] = useState<StudentConversation[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<Error | null>(null)

  useEffect(() => {
    const fetchConversations = async () => {
      try {
        setIsLoading(true)
        const {json} = await doFetchApi({
          path: `/api/v1/courses/${courseId}/ai_experiences/${aiExperienceId}/ai_conversations`,
        })
        const data = json as {conversations?: StudentConversation[]}
        setConversations(data.conversations || [])
      } catch (err) {
        setError(err as Error)
      } finally {
        setIsLoading(false)
      }
    }

    fetchConversations()
  }, [courseId, aiExperienceId])

  return {conversations, isLoading, error}
}

// Hook to fetch specific conversation details
export const useConversationDetail = (
  courseId: string | number,
  aiExperienceId: string | number,
  conversationId?: string,
) => {
  const [conversation, setConversation] = useState<ConversationDetail | null>(null)
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<Error | null>(null)

  useEffect(() => {
    if (!conversationId) {
      setConversation(null)
      return
    }

    const fetchConversation = async () => {
      try {
        setIsLoading(true)
        const {json} = await doFetchApi({
          path: `/api/v1/courses/${courseId}/ai_experiences/${aiExperienceId}/ai_conversations/${conversationId}`,
        })
        setConversation(json as ConversationDetail)
      } catch (err) {
        setError(err as Error)
      } finally {
        setIsLoading(false)
      }
    }

    fetchConversation()
  }, [courseId, aiExperienceId, conversationId])

  return {conversation, isLoading, error}
}

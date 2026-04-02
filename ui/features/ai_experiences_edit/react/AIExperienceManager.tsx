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

import React, {useState, useEffect} from 'react'
import {View} from '@instructure/ui-view'
import {LoadingIndicator} from '@instructure/platform-loading-indicator'
import doFetchApi, {FetchApiError} from '@canvas/do-fetch-api-effect'
import {showFlashError} from '@instructure/platform-alerts'
import {useScope as createI18nScope} from '@canvas/i18n'
import {AIExperience, AIExperienceFormData} from '../types'
import AIExperienceForm from './components/AIExperienceForm/AIExperienceForm'

const I18n = createI18nScope('ai_experiences_edit')

interface AIExperienceManagerProps {
  aiExperience?: AIExperience
  navbarHeight?: number
}

const AIExperienceManager: React.FC<AIExperienceManagerProps> = ({
  aiExperience: initialAIExperience,
}) => {
  const [aiExperience, setAIExperience] = useState<AIExperience | null>(initialAIExperience || null)
  const [isLoading, setIsLoading] = useState(false)
  const [isInitialLoading, setIsInitialLoading] = useState(true)

  useEffect(() => {
    const fetchAIExperience = async () => {
      const aiExperienceId = (window as any).ENV?.AI_EXPERIENCE_ID
      const courseId = (window as any).ENV?.COURSE_ID

      if (aiExperienceId && courseId && !aiExperience) {
        try {
          const {json} = await doFetchApi({
            path: `/courses/${courseId}/ai_experiences/${aiExperienceId}`,
            method: 'GET',
          })
          setAIExperience(json as AIExperience)
        } catch (error) {
          // TODO: Show flash alert to user for fetch error
        } finally {
          setIsInitialLoading(false)
        }
      } else {
        // No data to fetch (new experience), stop loading immediately
        setIsInitialLoading(false)
      }
    }

    fetchAIExperience()
  }, [])

  const handleSubmit = async (formData: AIExperienceFormData) => {
    setIsLoading(true)
    try {
      const courseId = ENV.COURSE_ID
      const isEdit = !!aiExperience?.id

      const path = isEdit
        ? `/courses/${courseId}/ai_experiences/${aiExperience.id}`
        : `/courses/${courseId}/ai_experiences`

      const method = isEdit ? 'PUT' : 'POST'

      // Set workflow_state to unpublished for draft
      const dataToSubmit = {
        ...formData,
        workflow_state: 'unpublished',
      }

      const {json} = await doFetchApi({
        path,
        method,
        body: {
          ai_experience: dataToSubmit,
        },
      })

      const updatedExperience = json as AIExperience
      setAIExperience(updatedExperience)

      if (updatedExperience.id) {
        window.location.href = `/courses/${courseId}/ai_experiences/${updatedExperience.id}`
      }
    } catch (error) {
      let message = I18n.t('An unexpected error occurred. Please try again.')
      if (error instanceof FetchApiError) {
        try {
          const body = await error.response.json()
          const baseErrors = body?.base
          if (Array.isArray(baseErrors) && baseErrors.length > 0) {
            message = baseErrors[0]
          }
        } catch {
          // Use default message if response body cannot be parsed
        }
      }
      showFlashError(I18n.t('Failed to save Knowledge Chat: %{error}', {error: message}))()
    } finally {
      setIsLoading(false)
    }
  }

  if (isInitialLoading) {
    return <LoadingIndicator />
  }

  return (
    <View as="div" padding="large">
      <AIExperienceForm aiExperience={aiExperience} onSubmit={handleSubmit} isLoading={isLoading} />
    </View>
  )
}

export default AIExperienceManager

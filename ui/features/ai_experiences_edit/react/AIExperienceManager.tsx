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

import React, {useState} from 'react'
import {View} from '@instructure/ui-view'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {AIExperience, AIExperienceFormData} from '../types'
import AIExperienceForm from './components/AIExperienceForm/AIExperienceForm'

interface AIExperienceManagerProps {
  aiExperience?: AIExperience
  navbarHeight?: number
}

const AIExperienceManager: React.FC<AIExperienceManagerProps> = ({
  aiExperience: initialAIExperience,
}) => {
  const [aiExperience, setAIExperience] = useState<AIExperience | null>(initialAIExperience || null)
  const [isLoading, setIsLoading] = useState(false)

  const handleSubmit = async (formData: AIExperienceFormData) => {
    setIsLoading(true)
    try {
      const courseId = ENV.COURSE_ID || ENV.COURSE?.id
      const isEdit = !!aiExperience?.id

      const path = isEdit
        ? `/api/v1/courses/${courseId}/ai_experiences/${aiExperience.id}`
        : `/api/v1/courses/${courseId}/ai_experiences`

      const method = isEdit ? 'PUT' : 'POST'

      const {json} = await doFetchApi({
        path,
        method,
        body: {
          ai_experience: formData,
        },
      })

      const updatedExperience = json as AIExperience
      setAIExperience(updatedExperience)
      console.log(
        `AI Experience ${isEdit ? 'updated' : 'created'} successfully:`,
        updatedExperience,
      )
    } catch (error) {
      console.error('Error saving AI Experience:', error)
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <View as="div" padding="large">
      <AIExperienceForm aiExperience={aiExperience} onSubmit={handleSubmit} isLoading={isLoading} />
    </View>
  )
}

export default AIExperienceManager

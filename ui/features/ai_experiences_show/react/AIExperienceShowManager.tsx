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

import React, {useState, useEffect} from 'react'
import {LoadingIndicator} from '@instructure/platform-loading-indicator'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashError} from '@instructure/platform-alerts'
import {useScope as createI18nScope} from '@canvas/i18n'
import {AIExperience} from '../types'
import AIExperienceShow from './components/AIExperienceShow'

const I18n = createI18nScope('ai_experiences_show')

const AIExperienceShowManager: React.FC = () => {
  const [aiExperience, setAIExperience] = useState<AIExperience | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    const fetchAIExperience = async () => {
      const aiExperienceId = (window as any).ENV?.AI_EXPERIENCE_ID
      const courseId = (window as any).ENV?.COURSE_ID

      try {
        const {json} = await doFetchApi({
          path: `/courses/${courseId}/ai_experiences/${aiExperienceId}`,
          method: 'GET',
        })
        setAIExperience(json as AIExperience)
      } catch {
        showFlashError(I18n.t('Failed to load Knowledge Chat. Please refresh the page.'))()
      } finally {
        setIsLoading(false)
      }
    }

    fetchAIExperience()
  }, [])

  if (isLoading) {
    return <LoadingIndicator />
  }

  if (!aiExperience) {
    return null
  }

  return <AIExperienceShow aiExperience={aiExperience} />
}

export default AIExperienceShowManager

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
import {useScope as createI18nScope} from '@canvas/i18n'
import {loadLearningMasteryGradebookSettings} from '../apiClient'
import {
  GradebookSettings,
  DisplayFilter,
  SecondaryInfoDisplay,
  NameDisplayFormat,
  ScoreDisplayFormat,
  OutcomeArrangement,
  DEFAULT_GRADEBOOK_SETTINGS,
} from '../utils/constants'

const I18n = createI18nScope('LearningMasteryGradebook')

interface UseGradebookSettingsReturn {
  settings: GradebookSettings
  isLoading: boolean
  error: string | null
  updateSettings: (newSettings: GradebookSettings) => void
}

const buildDisplayFilters = (apiSettings: any): DisplayFilter[] => {
  const displayFilters: DisplayFilter[] = []

  // If the API returns undefined for a filter, we fall back to the default setting for that filter
  if (
    apiSettings.show_student_avatars ??
    DEFAULT_GRADEBOOK_SETTINGS.displayFilters.includes(DisplayFilter.SHOW_STUDENT_AVATARS)
  ) {
    displayFilters.push(DisplayFilter.SHOW_STUDENT_AVATARS)
  }
  if (
    apiSettings.show_students_with_no_results ??
    DEFAULT_GRADEBOOK_SETTINGS.displayFilters.includes(DisplayFilter.SHOW_STUDENTS_WITH_NO_RESULTS)
  ) {
    displayFilters.push(DisplayFilter.SHOW_STUDENTS_WITH_NO_RESULTS)
  }
  if (
    apiSettings.show_outcomes_with_no_results ??
    DEFAULT_GRADEBOOK_SETTINGS.displayFilters.includes(DisplayFilter.SHOW_OUTCOMES_WITH_NO_RESULTS)
  ) {
    displayFilters.push(DisplayFilter.SHOW_OUTCOMES_WITH_NO_RESULTS)
  }

  return displayFilters
}

export const useGradebookSettings = (courseId: string): UseGradebookSettingsReturn => {
  const [settings, setSettings] = useState<GradebookSettings>(DEFAULT_GRADEBOOK_SETTINGS)
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const loadSettings = async () => {
      try {
        setIsLoading(true)
        setError(null)
        const response = await loadLearningMasteryGradebookSettings(courseId)

        if (response.status === 200 && response.data?.learning_mastery_gradebook_settings) {
          const apiSettings = response.data.learning_mastery_gradebook_settings

          const loadedSettings: GradebookSettings = {
            secondaryInfoDisplay:
              apiSettings.secondary_info_display ??
              (DEFAULT_GRADEBOOK_SETTINGS.secondaryInfoDisplay as SecondaryInfoDisplay),
            displayFilters: buildDisplayFilters(apiSettings),
            nameDisplayFormat:
              apiSettings.name_display_format ??
              (DEFAULT_GRADEBOOK_SETTINGS.nameDisplayFormat as NameDisplayFormat),
            studentsPerPage:
              apiSettings.students_per_page ?? DEFAULT_GRADEBOOK_SETTINGS.studentsPerPage,
            scoreDisplayFormat:
              apiSettings.score_display_format ??
              (DEFAULT_GRADEBOOK_SETTINGS.scoreDisplayFormat as ScoreDisplayFormat),
            outcomeArrangement:
              apiSettings.outcome_arrangement ??
              (DEFAULT_GRADEBOOK_SETTINGS.outcomeArrangement as OutcomeArrangement),
          }

          setSettings(loadedSettings)
        } else {
          setSettings(DEFAULT_GRADEBOOK_SETTINGS)
        }
      } catch (_) {
        setError(I18n.t('Failed to load settings'))
        setSettings(DEFAULT_GRADEBOOK_SETTINGS)
      } finally {
        setIsLoading(false)
      }
    }

    loadSettings()
  }, [courseId])

  const updateSettings = (newSettings: GradebookSettings) => {
    setSettings(newSettings)
  }

  return {
    settings,
    isLoading,
    error,
    updateSettings,
  }
}

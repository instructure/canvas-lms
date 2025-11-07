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
import {loadCourseUsers} from '../apiClient'
import {Student} from '../types/rollup'

const I18n = createI18nScope('LearningMasteryGradebook')

interface UseStudentsReturn {
  students: Student[]
  isLoading: boolean
  error: string | null
}

export const useStudents = (courseId: string, searchTerm?: string): UseStudentsReturn => {
  const [students, setStudents] = useState<Student[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const loadStudents = async () => {
      try {
        setIsLoading(true)
        setError(null)
        const response = await loadCourseUsers(courseId, searchTerm)

        if (response.status === 200 && response.data) {
          setStudents(response.data)
        }
      } catch (_) {
        setError(I18n.t('Failed to load students'))
        setStudents([])
      } finally {
        setIsLoading(false)
      }
    }

    loadStudents()
  }, [courseId, searchTerm])

  return {
    students,
    isLoading,
    error,
  }
}

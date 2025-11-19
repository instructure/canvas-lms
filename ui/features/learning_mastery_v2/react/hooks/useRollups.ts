/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {groupBy} from 'lodash'
import {loadRollups} from '../apiClient'
import {useScope as createI18nScope} from '@canvas/i18n'
import {
  StudentRollup,
  Outcome,
  Rating,
  Student,
  OutcomeRollup,
  RollupsResponse,
  StudentRollupData,
  Pagination,
} from '../types/rollup'
import {
  DEFAULT_PAGE_NUMBER,
  DEFAULT_STUDENTS_PER_PAGE,
  SortOrder,
  SortBy,
  GradebookSettings,
} from '../utils/constants'
import {Sorting} from '../types/shapes'
import axios from '@canvas/axios'
import {mapSettingsToFilters} from '../utils/filter'

const I18n = createI18nScope('OutcomeManagement')

interface UseRollupsProps {
  courseId: string | number
  accountMasteryScalesEnabled: boolean
  settings?: GradebookSettings | null
  enabled?: boolean
}

interface UseRollupsReturn extends RollupData {
  isLoading: boolean
  error: null | string
  setCurrentPage: (page: number) => void
  sorting: Sorting
}

interface RollupData {
  rollups: StudentRollupData[]
  outcomes: Outcome[]
  students: Student[]
  pagination?: Pagination
}

const getRow = (studentRollups: StudentRollup[], outcomes: Outcome[]): OutcomeRollup[] =>
  studentRollups[0].scores.map(score => {
    const outcome = outcomes.find(o => o.id === score.links.outcome)!
    const rating = findRating(outcome.ratings, score.score)
    return {
      outcomeId: outcome.id,
      rating: {
        ...rating,
        color: `#` + rating.color,
      },
    }
  })

const findRating = (ratings: Rating[], score: number): Rating => {
  const rating = ratings.find(
    (r, i) =>
      r.points === score ||
      (i === 0 && score > r.points) ||
      (score > r.points && ratings[i - 1].points > score),
  )
  return rating || ratings[ratings.length - 1]
}

const getStudents = (rollups: StudentRollup[], users: Student[]): Student[] => {
  const students = users.map(user => {
    const rollup = rollups.find(r => r.links.user === user.id)!
    const status = rollup.links.status === 'completed' ? 'concluded' : rollup.links.status
    return {
      ...user,
      status,
    }
  })

  return students
}

const rollupsByUser = (rollups: StudentRollup[], outcomes: Outcome[]): StudentRollupData[] => {
  const rollupsByUserId = groupBy(rollups, rollup => rollup.links.user)
  return Object.entries(rollupsByUserId).map(([studentId, studentRollups]) => ({
    studentId,
    outcomeRollups: getRow(studentRollups, outcomes),
  }))
}

export default function useRollups({
  courseId,
  accountMasteryScalesEnabled,
  settings = null,
  enabled = true,
}: UseRollupsProps): UseRollupsReturn {
  const [isLoading, setIsLoading] = useState<boolean>(true)
  const [error, setError] = useState<null | string>(null)
  const [currentPage, setCurrentPage] = useState<number>(DEFAULT_PAGE_NUMBER)
  const [data, setData] = useState<RollupData>({
    rollups: [],
    outcomes: [],
    students: [],
  })
  const [sortOrder, setSortOrder] = useState<SortOrder>(SortOrder.ASC)
  const [sortBy, setSortBy] = useState<SortBy>(SortBy.SortableName)
  const [sortOutcomeId, setSortOutcomeId] = useState<string | null>(null)

  const needMasteryAndColorDefaults = !accountMasteryScalesEnabled

  useEffect(() => {
    if (!enabled) {
      setIsLoading(true)
      return
    }
    ;(async () => {
      try {
        setIsLoading(true)
        const {data} = (await loadRollups(
          courseId,
          settings ? mapSettingsToFilters(settings) : [],
          needMasteryAndColorDefaults,
          currentPage,
          settings?.studentsPerPage,
          sortOrder,
          sortBy,
          sortOutcomeId || undefined,
        )) as RollupsResponse
        const {users: fetchedUsers, outcomes: fetchedOutcomes} = data.linked
        const students = getStudents(data.rollups, fetchedUsers)
        const rollups = rollupsByUser(data.rollups, fetchedOutcomes)
        setData({
          rollups,
          outcomes: fetchedOutcomes,
          students,
          pagination: {
            currentPage: data.meta.pagination.page,
            perPage: data.meta.pagination.per_page,
            totalPages: data.meta.pagination.page_count,
            totalCount: data.meta.pagination.count,
          },
        })
      } catch (e) {
        if (e instanceof axios.AxiosError) {
          setError((e as any)?.message || I18n.t('Error loading rollups'))
        } else {
          setError(I18n.t('Error loading rollups'))
        }
      } finally {
        setIsLoading(false)
      }
    })()
  }, [
    courseId,
    needMasteryAndColorDefaults,
    currentPage,
    sortOrder,
    sortBy,
    sortOutcomeId,
    settings,
    enabled,
  ])

  return {
    isLoading,
    error,
    students: data.students,
    outcomes: data.outcomes,
    rollups: data.rollups,
    pagination: data.pagination
      ? {...data.pagination, perPage: settings?.studentsPerPage || DEFAULT_STUDENTS_PER_PAGE}
      : undefined,
    setCurrentPage,
    sorting: {
      sortOrder,
      setSortOrder,
      sortBy,
      setSortBy,
      sortOutcomeId,
      setSortOutcomeId,
    },
  }
}

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
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
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

const I18n = createI18nScope('OutcomeManagement')

interface UseRollupsProps {
  courseId: string | number
  accountMasteryScalesEnabled: boolean
}

interface UseRollupsReturn extends RollupData {
  isLoading: boolean
  gradebookFilters: string[]
  setGradebookFilters: React.Dispatch<React.SetStateAction<string[]>>
  setCurrentPage: (page: number) => void
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
}: UseRollupsProps): UseRollupsReturn {
  const [isLoading, setIsLoading] = useState<boolean>(true)
  const [gradebookFilters, setGradebookFilters] = useState<string[]>([])
  const [currentPage, setCurrentPage] = useState<number>(1)
  const [data, setData] = useState<RollupData>({
    rollups: [],
    outcomes: [],
    students: [],
  })

  const needMasteryAndColorDefaults = !accountMasteryScalesEnabled

  useEffect(() => {
    ;(async () => {
      try {
        setIsLoading(true)
        const {data} = (await loadRollups(
          courseId,
          gradebookFilters,
          needMasteryAndColorDefaults,
          currentPage,
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
          },
        })
        setIsLoading(false)
      } catch (_e) {
        showFlashAlert({
          message: I18n.t('Error loading rollups'),
          type: 'error',
        })
      }
    })()
  }, [courseId, needMasteryAndColorDefaults, gradebookFilters, currentPage])

  return {
    isLoading,
    students: data.students,
    outcomes: data.outcomes,
    rollups: data.rollups,
    gradebookFilters,
    setGradebookFilters,
    pagination: data.pagination,
    setCurrentPage,
  }
}

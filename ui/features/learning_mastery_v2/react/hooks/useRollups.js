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
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('OutcomeManagement')

const getRow = (studentRollups, outcomes) =>
  studentRollups[0].scores.map(score => {
    const outcome = outcomes.find(o => o.id === score.links.outcome)
    const rating = findRating(outcome.ratings, score.score)
    return {
      outcomeId: outcome.id,
      rating: {
        ...rating,
        color: `#` + rating.color,
      },
    }
  })

const findRating = (ratings, score) => {
  const rating = ratings.find(
    (r, i) =>
      r.points === score ||
      (i === 0 && score > r.points) ||
      (score > r.points && ratings[i - 1].points > score)
  )
  return rating || ratings[ratings.length - 1]
}

const rollupsByUser = (rollups, outcomes) => {
  const rollupsByUserId = groupBy(rollups, rollup => rollup.links.user)
  return Object.entries(rollupsByUserId).map(([studentId, studentRollups]) => ({
    studentId,
    outcomeRollups: getRow(studentRollups, outcomes),
  }))
}

export default function useRollups({courseId, accountMasteryScalesEnabled}) {
  const [isLoading, setIsLoading] = useState(true)
  const [students, setStudents] = useState([])
  const [outcomes, setOutcomes] = useState([])
  const [rollups, setRollups] = useState([])

  const needMasteryAndColorDefaults = !accountMasteryScalesEnabled

  useEffect(() => {
    ;(async () => {
      try {
        const {data} = await loadRollups(courseId, needMasteryAndColorDefaults)
        const {users: fetchedUsers, outcomes: fetchedOutcomes} = data.linked
        setStudents(fetchedUsers)
        setOutcomes(fetchedOutcomes)
        setRollups(rollupsByUser(data.rollups, fetchedOutcomes))
        setIsLoading(false)
      } catch (_e) {
        showFlashAlert({
          message: I18n.t('Error loading rollups'),
          type: 'error',
        })
      }
    })()
  }, [courseId, needMasteryAndColorDefaults])

  return {
    isLoading,
    students,
    outcomes,
    rollups,
  }
}

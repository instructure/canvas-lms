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
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {loadRollups} from '../apiClient'
import I18n from 'i18n!OutcomeManagement'

export default function useRollups({courseId}) {
  const [isLoading, setIsLoading] = useState(true)
  const [students, setStudents] = useState([])
  const [outcomes, setOutcomes] = useState([])
  useEffect(() => {
    ;(async () => {
      try {
        const {data} = await loadRollups(courseId)
        setStudents(data.linked.users)
        setOutcomes(data.linked.outcomes)
        setIsLoading(false)
      } catch (e) {
        showFlashAlert({
          message: I18n.t('Error loading rollups'),
          type: 'error'
        })
      }
    })()
  }, [courseId])

  return {
    isLoading,
    students,
    outcomes
  }
}

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

import {useMemo, useState} from 'react'
import useSearch from '@canvas/outcomes/react/hooks/useSearch'
import type {MasteryFilter, MasteryLevel, Outcome} from '../types'

const MASTERY_LEVELS: MasteryLevel[] = ['mastery', 'exceeds_mastery']
const NOT_STARTED_LEVELS: MasteryLevel[] = ['unassessed']
const EXCLUDED_FROM_IN_PROGRESS: MasteryLevel[] = [...MASTERY_LEVELS, ...NOT_STARTED_LEVELS]

export const useOutcomeFilters = (outcomes: Outcome[]) => {
  const {
    search,
    debouncedSearch,
    onChangeHandler: onSearchChangeHandler,
    onClearHandler: onSearchClearHandler,
  } = useSearch(300)

  const [masteryFilter, setMasteryFilter] = useState<MasteryFilter>('all')

  const filteredOutcomes = useMemo(() => {
    let filtered = outcomes

    if (masteryFilter !== 'all') {
      filtered = filtered.filter(outcome => {
        switch (masteryFilter) {
          case 'mastery':
            return MASTERY_LEVELS.includes(outcome.masteryLevel)
          case 'not_started':
            return NOT_STARTED_LEVELS.includes(outcome.masteryLevel)
          case 'in_progress':
            return !EXCLUDED_FROM_IN_PROGRESS.includes(outcome.masteryLevel)
          default:
            return true
        }
      })
    }

    if (debouncedSearch) {
      const searchLower = debouncedSearch.toLowerCase()
      filtered = filtered.filter(
        outcome =>
          outcome.code?.toLowerCase().includes(searchLower) ||
          outcome.name?.toLowerCase().includes(searchLower) ||
          outcome.description?.toLowerCase().includes(searchLower),
      )
    }

    return filtered
  }, [outcomes, debouncedSearch, masteryFilter])

  return {
    search,
    onSearchChangeHandler,
    onSearchClearHandler,
    masteryFilter,
    setMasteryFilter,
    filteredOutcomes,
  }
}

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

import {useMemo, useRef, useEffect, useCallback, type ReactNode} from 'react'
import CanvasMultiSelect from '@canvas/multi-select'
import {useScope as createI18nScope} from '@canvas/i18n'
import {IconSearchLine} from '@instructure/ui-icons'
import useDebouncedSearchTerm from '@canvas/search-item-selector/react/hooks/useDebouncedSearchTerm'
import {useOutcomes} from '../../hooks/useOutcomes'

const I18n = createI18nScope('LearningMasteryGradebook')

interface OutcomeSearchProps {
  courseId: string
  selectedOutcomes?: string[]
  onSelectOutcomes: (outcomeIds: string[]) => void
}

interface OutcomeCache {
  [id: string]: {
    _id: string
    title: string
  }
}

export const OutcomeSearch = ({
  selectedOutcomes = [],
  courseId,
  onSelectOutcomes,
}: OutcomeSearchProps) => {
  const {searchTerm: outcomeSearchTerm, setSearchTerm: setOutcomeSearchTerm} =
    useDebouncedSearchTerm('')
  const {outcomes, isLoading: isLoadingOutcomes} = useOutcomes({
    courseId,
    searchTerm: outcomeSearchTerm,
  })

  // Cache outcome data so we can render selected outcomes even when they're not in search results
  const outcomeCacheRef = useRef<OutcomeCache>({})

  useEffect(() => {
    outcomes.forEach(outcome => {
      outcomeCacheRef.current[outcome.node._id] = {
        _id: outcome.node._id,
        title: outcome.node.title,
      }
    })
  }, [outcomes])

  const allOutcomes = useMemo(() => {
    const outcomeMap = new Map()

    selectedOutcomes.forEach(id => {
      if (outcomeCacheRef.current[id]) {
        outcomeMap.set(id, outcomeCacheRef.current[id])
      }
    })

    if (!isLoadingOutcomes) {
      outcomes.forEach(outcome => {
        outcomeMap.set(outcome.node._id, outcome.node)
      })
    }

    return Array.from(outcomeMap.values())
  }, [outcomes, selectedOutcomes, isLoadingOutcomes])

  const onSelect = useCallback(
    (selectedIds: string[]) => {
      onSelectOutcomes(selectedIds)
      setOutcomeSearchTerm('')
    },
    [onSelectOutcomes, setOutcomeSearchTerm],
  )

  const renderBeforeInput = useCallback(
    (tags: ReactNode[]) => [<IconSearchLine key="search-icon" />, ...(tags || [])],
    [],
  )

  return (
    <CanvasMultiSelect
      label={I18n.t('Outcomes')}
      onChange={onSelect}
      placeholder={I18n.t('Search outcomes')}
      selectedOptionIds={selectedOutcomes}
      customRenderBeforeInput={renderBeforeInput}
      customOnInputChange={(value: string) => setOutcomeSearchTerm(value)}
      customMatcher={() => true}
      isLoading={isLoadingOutcomes}
    >
      {allOutcomes.map(outcome => (
        <CanvasMultiSelect.Option
          key={outcome._id}
          id={String(outcome._id)}
          label={outcome.title}
          value={String(outcome._id)}
        >
          {outcome.title}
        </CanvasMultiSelect.Option>
      ))}
    </CanvasMultiSelect>
  )
}

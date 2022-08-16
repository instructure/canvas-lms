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

import React, {useState, useEffect, useRef} from 'react'
import uuid from 'uuid'
import {useScope as useI18nScope} from '@canvas/i18n'
import {chunk} from 'lodash'
import {View} from '@instructure/ui-view'
import {Button} from '@instructure/ui-buttons'
import {TextInput} from '@instructure/ui-text-input'
import {Flex} from '@instructure/ui-flex'
import FilterComponent from './FilterTrayFilter'
import type {
  AssignmentGroup,
  GradingPeriod,
  Module,
  PartialFilterPreset,
  FilterPreset,
  Filter,
  FilterType,
  Section,
  StudentGroupCategoryMap
} from '../gradebook.d'
import {isFilterNotEmpty} from '../Gradebook.utils'

const I18n = useI18nScope('gradebook')

const {Item: FlexItem} = Flex as any

export type FilterTrayPresetProps = {
  applyFilters: (filters: PartialFilterPreset['filters']) => void
  assignmentGroups: AssignmentGroup[]
  filterPreset: PartialFilterPreset | FilterPreset
  gradingPeriods: GradingPeriod[]
  isActive: boolean
  modules: Module[]
  onChange?: (filter: PartialFilterPreset) => void
  onCreate?: (filter: PartialFilterPreset) => void
  onUpdate?: (filter: FilterPreset) => Promise<void>
  onDelete: () => void
  sections: Section[]
  studentGroupCategories: StudentGroupCategoryMap
}

export default function FilterTrayPreset({
  applyFilters,
  assignmentGroups,
  filterPreset,
  gradingPeriods,
  isActive,
  modules,
  onCreate,
  onUpdate,
  onDelete,
  sections,
  studentGroupCategories
}: FilterTrayPresetProps) {
  const [name, setName] = useState(filterPreset.name)
  const [filterPresetWasChanged, setFilterPresetWasChanged] = useState(false)
  const [stagedFilters, setStagedFilters] = useState(filterPreset.filters)
  const inputRef = useRef<HTMLInputElement | null>(null)

  useEffect(() => {
    setName(filterPreset.name)
  }, [filterPreset.name])

  useEffect(() => {
    setStagedFilters(filterPreset.filters)
  }, [filterPreset.filters])

  const onChangeFilter = filter => {
    const otherFilters = stagedFilters.filter(c => c.id !== filter.id)
    if (otherFilters.find(c => c.type === filter.type)) {
      throw new Error('filter type already exists')
    }

    const newFilters = otherFilters
      .concat(filter)
      .sort((a, b) => (a.created_at < b.created_at ? -1 : 1))

    setStagedFilters(newFilters)
    setFilterPresetWasChanged(true)
  }

  const handleCreateFilter = () => {
    if (onCreate) {
      onCreate({
        ...filterPreset,
        name,
        filters: stagedFilters.filter(isFilterNotEmpty)
      })
      setFilterPresetWasChanged(false)
    }
  }

  const handleSaveFilter = () => {
    if (onUpdate) {
      const updatedFilter = {
        ...filterPreset,
        name,
        filters: stagedFilters.filter(isFilterNotEmpty)
      } as FilterPreset
      onUpdate(updatedFilter)
      setFilterPresetWasChanged(false)
      if (isActive) {
        applyFilters(stagedFilters.filter(isFilterNotEmpty))
      }
    }
  }

  const ensureFilter = (filters: Filter[], type: FilterType): Filter => {
    return (
      filters.find(filter => filter.type === type) || {
        id: uuid.v4(),
        type,
        value: undefined,
        created_at: new Date().toISOString()
      }
    )
  }

  const sectionFilter = sections.length > 0 ? ensureFilter(stagedFilters, 'section') : undefined

  const moduleFilter = modules.length > 0 ? ensureFilter(stagedFilters, 'module') : undefined

  const assignmentGroupFilter =
    assignmentGroups.length > 0 ? ensureFilter(stagedFilters, 'assignment-group') : undefined

  const studentGroupFilter =
    studentGroupCategories.length > 0 ? ensureFilter(stagedFilters, 'student-group') : undefined

  // make the order of filters consistent
  const filtersWithItemsChunks = chunk(
    [sectionFilter, moduleFilter, assignmentGroupFilter, studentGroupFilter].filter(
      x => x
    ) as Filter[],
    2
  )

  const gradingPeriodFilter = ensureFilter(stagedFilters, 'grading-period')
  const submissionFilter = ensureFilter(stagedFilters, 'submissions')
  const startDateFilter = ensureFilter(stagedFilters, 'start-date')
  const endDateFilter = ensureFilter(stagedFilters, 'end-date')

  const filtersAlwaysShownChunks = [
    [gradingPeriodFilter, submissionFilter],
    [startDateFilter, endDateFilter]
  ]

  const isSaveButtonEnabled =
    name?.trim().length > 0 &&
    stagedFilters.filter(isFilterNotEmpty).length > 0 &&
    (!filterPreset.id || filterPresetWasChanged)

  return (
    <View
      as="div"
      background="secondary"
      padding="small"
      borderRadius="medium"
      margin="0 0 x-small 0"
    >
      <View as="div" padding="xx-small 0 xx-small xx-small">
        <Flex margin="0 0 small 0" padding="0 xx-small 0 0">
          <TextInput
            inputRef={ref => (inputRef.current = ref)}
            width="100%"
            renderLabel={I18n.t('Filter preset name')}
            placeholder={I18n.t('Give your filter preset a name')}
            value={name}
            onChange={(_event, value) => {
              setName(value)
              setFilterPresetWasChanged(true)
            }}
          />
        </Flex>
        {filtersWithItemsChunks.map((filters, index) => (
          // eslint-disable-next-line react/no-array-index-key
          <Flex key={`chunk-${index}`} margin="small 0">
            {filters.map(filter => (
              <FlexItem key={filter.id} size="50%" padding="0 xx-small 0 0">
                <FilterComponent
                  assignmentGroups={assignmentGroups}
                  filter={filter}
                  gradingPeriods={gradingPeriods}
                  modules={modules}
                  onChange={onChangeFilter}
                  sections={sections}
                  studentGroupCategories={studentGroupCategories}
                />
              </FlexItem>
            ))}
          </Flex>
        ))}
        {filtersAlwaysShownChunks.map((filters, index) => (
          // eslint-disable-next-line react/no-array-index-key
          <Flex key={`always-shown-${index}`} margin="small 0">
            {filters.map(filter => (
              <FlexItem key={filter.id} size="50%" padding="0 xx-small 0 0">
                <FilterComponent
                  assignmentGroups={assignmentGroups}
                  filter={filter}
                  gradingPeriods={gradingPeriods}
                  modules={modules}
                  onChange={onChangeFilter}
                  sections={sections}
                  studentGroupCategories={studentGroupCategories}
                />
              </FlexItem>
            ))}
          </Flex>
        ))}

        <Flex justifyItems="end" margin="0 xx-small">
          <FlexItem margin="0 0 0 small">
            <Button
              color="secondary"
              data-testid="delete-filter-preset-button"
              margin="small 0 0 0"
              onClick={onDelete}
            >
              {filterPreset.id ? I18n.t('Delete Preset') : I18n.t('Clear')}
            </Button>
          </FlexItem>

          <FlexItem margin="0 0 0 small">
            <Button
              color="primary"
              data-testid="save-filter-button"
              margin="small 0 0 0"
              onClick={filterPreset.id ? handleSaveFilter : handleCreateFilter}
              interaction={isSaveButtonEnabled ? 'enabled' : 'disabled'}
            >
              {I18n.t('Save Filter Preset')}
            </Button>
          </FlexItem>
        </Flex>
      </View>
    </View>
  )
}

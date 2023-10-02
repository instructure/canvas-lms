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
import {ToggleGroup} from '@instructure/ui-toggle-details'
import {Text} from '@instructure/ui-text'
import {TruncateText} from '@instructure/ui-truncate-text'
import type {CamelizedGradingPeriod} from '@canvas/grading/grading.d'
import type {Filter, FilterPreset, FilterType, PartialFilterPreset} from '../gradebook.d'
import type {AssignmentGroup, Module, Section, StudentGroupCategoryMap} from '../../../../../api.d'
import {isFilterNotEmpty} from '../Gradebook.utils'

const I18n = useI18nScope('gradebook')

export type FilterTrayPresetProps = {
  applyFilters: (filters: PartialFilterPreset['filters']) => void
  assignmentGroups: AssignmentGroup[]
  filterPreset: PartialFilterPreset | FilterPreset
  gradingPeriods: CamelizedGradingPeriod[]
  isActive: boolean
  modules: Module[]
  onCreate?: (filter: PartialFilterPreset) => Promise<boolean>
  onUpdate?: (filter: FilterPreset) => Promise<boolean>
  onDelete?: () => void
  onToggle: (expanded: boolean) => void
  isExpanded: boolean
  sections: Section[]
  studentGroupCategories: StudentGroupCategoryMap
  closeRef: React.RefObject<any>
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
  onToggle,
  isExpanded,
  sections,
  studentGroupCategories,
  closeRef,
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

  const onChangeFilter = (filter: Filter) => {
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
      return onCreate({
        ...filterPreset,
        name,
        filters: stagedFilters.filter(isFilterNotEmpty),
      }).then(success => {
        if (success) {
          closeRef?.current?.focus()
          setName('')
          setStagedFilters(filterPreset.filters)
          setFilterPresetWasChanged(false)
        } else {
          setFilterPresetWasChanged(true)
        }
      })
    }
  }

  const handleSaveFilter = () => {
    if (onUpdate) {
      const updatedFilter = {
        ...filterPreset,
        name,
        filters: stagedFilters.filter(isFilterNotEmpty),
      } as FilterPreset
      return onUpdate(updatedFilter).then(success => {
        if (success) {
          closeRef?.current?.focus()
          setFilterPresetWasChanged(false)
        }
        if (isActive) {
          applyFilters(stagedFilters.filter(isFilterNotEmpty))
        }
      })
    }
  }

  const ensureFilter = (filters: Filter[], type: FilterType): Filter =>
    filters.find(filter => filter.type === type) || {
      id: uuid.v4(),
      type,
      value: undefined,
      created_at: new Date().toISOString(),
    }

  const sectionFilter = sections.length > 0 ? ensureFilter(stagedFilters, 'section') : undefined

  const moduleFilter = modules.length > 0 ? ensureFilter(stagedFilters, 'module') : undefined

  const assignmentGroupFilter =
    assignmentGroups.length > 1 ? ensureFilter(stagedFilters, 'assignment-group') : undefined

  const studentGroupFilter =
    Object.values(studentGroupCategories).length > 0
      ? ensureFilter(stagedFilters, 'student-group')
      : undefined

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
    [startDateFilter, endDateFilter],
  ]

  const isSaveButtonEnabled =
    name?.trim().length > 0 &&
    stagedFilters.filter(isFilterNotEmpty).length > 0 &&
    (!filterPreset.id || filterPresetWasChanged)

  return (
    <ToggleGroup
      toggleLabel={I18n.t('Toggle %{filterPresetName}', {
        filterPresetName: filterPreset.name || I18n.t('Create Filter Preset'),
      })}
      onToggle={(_event: React.MouseEvent, expanded: boolean) => {
        onToggle(expanded)
      }}
      data-testid={`${filterPreset.name || 'create-filter-preset'}-dropdown`}
      expanded={isExpanded}
      summary={
        <Flex margin="0 0 0 xxx-small">
          <Flex direction="column">
            <View>
              <TruncateText position="middle">
                {filterPreset.id ? filterPreset.name : I18n.t('Create Filter Preset')}
              </TruncateText>
            </View>
            {filterPreset.id && (
              <View>
                <Text size="small" color="secondary">
                  {I18n.t(
                    {
                      zero: 'No Filters',
                      one: '1 Filter',
                      other: '{{count}} Filters',
                    },
                    {
                      count: stagedFilters.filter(isFilterNotEmpty).length,
                    }
                  )}
                </Text>
              </View>
            )}
          </Flex>
        </Flex>
      }
    >
      <View as="div" padding="small" borderRadius="medium">
        <View as="div" padding="xx-small 0 xx-small xx-small">
          <Flex margin="0 0 small 0" padding="0 xx-small 0 0">
            <TextInput
              inputRef={ref => {
                if (ref instanceof HTMLInputElement) {
                  inputRef.current = ref
                }
              }}
              width="100%"
              data-testid="filter-preset-name-input"
              renderLabel={I18n.t('Filter preset name')}
              placeholder={I18n.t('Give your filter preset a name')}
              value={name}
              onChange={(_event: React.ChangeEvent<HTMLInputElement>, value: string) => {
                setName(value)
                setFilterPresetWasChanged(true)
              }}
            />
          </Flex>

          {filtersWithItemsChunks.map((filters, index) => (
            // eslint-disable-next-line react/no-array-index-key
            <Flex key={`chunk-${index}`} margin="small 0">
              {filters.map(filter => (
                <Flex.Item key={filter.id} size="50%" padding="0 xx-small 0 0">
                  <FilterComponent
                    assignmentGroups={assignmentGroups}
                    filter={filter}
                    gradingPeriods={gradingPeriods}
                    modules={modules}
                    onChange={onChangeFilter}
                    sections={sections}
                    studentGroupCategories={studentGroupCategories}
                  />
                </Flex.Item>
              ))}
            </Flex>
          ))}

          {filtersAlwaysShownChunks.map((filters, index) => (
            // eslint-disable-next-line react/no-array-index-key
            <Flex key={`always-shown-${index}`} margin="small 0">
              {filters.map(filter => (
                <Flex.Item key={filter.id} size="50%" padding="0 xx-small 0 0">
                  <FilterComponent
                    assignmentGroups={assignmentGroups}
                    filter={filter}
                    gradingPeriods={gradingPeriods}
                    modules={modules}
                    onChange={onChangeFilter}
                    sections={sections}
                    studentGroupCategories={studentGroupCategories}
                  />
                </Flex.Item>
              ))}
            </Flex>
          ))}

          <Flex justifyItems="end" margin="0 xx-small">
            <Flex.Item margin="0 0 0 small">
              <Button
                color="secondary"
                data-testid="delete-filter-preset-button"
                margin="small 0 0 0"
                onClick={() => {
                  if (filterPreset.id && onDelete) {
                    onDelete()
                  } else {
                    setStagedFilters([])
                  }
                }}
              >
                {filterPreset.id ? I18n.t('Delete Preset') : I18n.t('Clear')}
              </Button>
            </Flex.Item>

            <Flex.Item margin="0 0 0 small">
              <Button
                color="primary"
                data-testid="save-filter-button"
                margin="small 0 0 0"
                onClick={filterPreset.id ? handleSaveFilter : handleCreateFilter}
                interaction={isSaveButtonEnabled ? 'enabled' : 'disabled'}
              >
                {I18n.t('Save Filter Preset')}
              </Button>
            </Flex.Item>
          </Flex>
        </View>
      </View>
    </ToggleGroup>
  )
}

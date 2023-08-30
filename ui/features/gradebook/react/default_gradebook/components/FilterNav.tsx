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

import React, {useState, useCallback, useRef, SetStateAction} from 'react'
import {Link} from '@instructure/ui-link'
import {AccessibleContent} from '@instructure/ui-a11y-content'
import uuid from 'uuid'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {Tag} from '@instructure/ui-tag'
import {Alert} from '@instructure/ui-alerts'
import type {CamelizedGradingPeriod} from '@canvas/grading/grading.d'
import type {Filter, FilterPreset} from '../gradebook.d'
import type {AssignmentGroup, Module, Section, StudentGroupCategoryMap} from '../../../../../api.d'
import {doFiltersMatch, getLabelForFilter, isFilterNotEmpty} from '../Gradebook.utils'
import useStore from '../stores/index'
import FilterDropdown from './FilterDropdown'
import FilterNavDateModal from './FilterDateModal'
import FilterTray from './FilterTray'
import {useFilterDropdownData} from './FilterNav.utils'
import {GradeStatus} from '@canvas/grading/accountGradingStatus'

const I18n = useI18nScope('gradebook')

export type FilterNavProps = {
  modules: Module[]
  assignmentGroups: AssignmentGroup[]
  sections: Section[]
  gradingPeriods: CamelizedGradingPeriod[]
  studentGroupCategories: StudentGroupCategoryMap
  customStatuses: GradeStatus[]
}

export default function FilterNav({
  assignmentGroups,
  gradingPeriods,
  modules,
  sections,
  studentGroupCategories,
  customStatuses,
}: FilterNavProps) {
  const [isTrayOpen, setIsTrayOpen] = useState(false)
  const [isDateModalOpen, setIsDateModalOpen] = useState(false)
  const [announcement, setAnnouncement] = useState('')
  const filterPresets = useStore(state => state.filterPresets)
  const applyFilters = useStore(state => state.applyFilters)
  const addFilters = useStore(state => state.addFilters)
  const appliedFilters = useStore(state => state.appliedFilters)
  const applyFiltersButtonRef = useRef<HTMLButtonElement>(null)

  const handleClearFilters = () => {
    setAnnouncement(I18n.t('All Filters Have Been Cleared'))
    applyFilters([])
    applyFiltersButtonRef.current?.focus()
  }

  const activeFilterComponents = appliedFilters.filter(isFilterNotEmpty).map(filter => {
    const label = getLabelForFilter(
      filter,
      assignmentGroups,
      gradingPeriods,
      modules,
      sections,
      studentGroupCategories,
      customStatuses
    )

    const handleDeleteFilterClick = () => {
      setAnnouncement(I18n.t('Removed %{filterName} Filter', {filterName: label}))
      useStore.setState({
        appliedFilters: appliedFilters.filter(c => c.id !== filter.id),
      })
    }

    return (
      <Tag
        data-testid={`applied-filter-${label}`}
        key={`staged-filter-${filter.id}`}
        text={
          <AccessibleContent alt={I18n.t('Remove %{filterName} Filter', {filterName: label})}>
            {label}
          </AccessibleContent>
        }
        dismissible={true}
        onClick={handleDeleteFilterClick}
        margin="0 xx-small 0 0"
      />
    )
  })

  const onToggleFilterPreset = useCallback(
    (filterPreset: FilterPreset) => {
      if (doFiltersMatch(appliedFilters, filterPreset.filters)) {
        applyFilters([])
      } else {
        applyFilters(filterPreset.filters)
      }
    },
    [appliedFilters, applyFilters]
  )

  const {dataMap, filterItems} = useFilterDropdownData({
    appliedFilters,
    assignmentGroups,
    filterPresets,
    gradingPeriods,
    modules,
    sections,
    studentGroupCategories,
    onToggleFilterPreset,
    customStatuses,
    onToggleDateModal: () => setIsDateModalOpen(true),
  })

  const startDate = appliedFilters.find((c: Filter) => c.type === 'start-date')?.value || null

  const endDate = appliedFilters.find((c: Filter) => c.type === 'end-date')?.value || null

  const changeAnnouncement = (filterAnnouncement: SetStateAction<string>) => {
    setAnnouncement(filterAnnouncement)
  }

  return (
    <Flex justifyItems="space-between" padding="0 0 small 0">
      <Alert
        screenReaderOnly={true}
        liveRegionPoliteness="assertive"
        liveRegion={() => document.getElementById('flash_screenreader_holder') as HTMLElement}
      >
        {announcement}
      </Alert>
      <Flex.Item>
        <Flex>
          <Flex.Item padding="0 small 0 0">
            <FilterDropdown
              onOpenTray={() => setIsTrayOpen(true)}
              dataMap={dataMap}
              filterItems={filterItems}
              changeAnnouncement={changeAnnouncement}
              applyFiltersButtonRef={applyFiltersButtonRef}
            />
          </Flex.Item>
          <Flex.Item data-testid="filter-tags">
            {activeFilterComponents.length > 0 && activeFilterComponents}
          </Flex.Item>
        </Flex>
      </Flex.Item>

      <Flex.Item>
        {activeFilterComponents.length > 0 && (
          <Link
            isWithinText={false}
            as="button"
            margin="0"
            onClick={handleClearFilters}
            data-testid="clear-all-filters"
          >
            {I18n.t('Clear All Filters')}
          </Link>
        )}
      </Flex.Item>

      <FilterTray
        isTrayOpen={isTrayOpen}
        setIsTrayOpen={setIsTrayOpen}
        filterPresets={filterPresets}
        assignmentGroups={assignmentGroups}
        gradingPeriods={gradingPeriods}
        studentGroupCategories={studentGroupCategories}
        modules={modules}
        sections={sections}
      />

      <FilterNavDateModal
        startDate={startDate}
        endDate={endDate}
        isOpen={isDateModalOpen}
        onCloseDateModal={() => setIsDateModalOpen(false)}
        onSelectDates={(startDateValue: string | null, endDateValue: string | null) => {
          const startDateCondition: Filter = {
            id: uuid.v4(),
            type: 'start-date',
            value: startDateValue,
            created_at: new Date().toISOString(),
          }
          const endDateCondition: Filter = {
            id: uuid.v4(),
            type: 'end-date',
            value: endDateValue,
            created_at: new Date().toISOString(),
          }
          addFilters([startDateCondition, endDateCondition])
        }}
      />
    </Flex>
  )
}

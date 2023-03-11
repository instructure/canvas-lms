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

import React, {useState} from 'react'
import {Link} from '@instructure/ui-link'
import {AccessibleContent} from '@instructure/ui-a11y-content'
import uuid from 'uuid'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {Tag} from '@instructure/ui-tag'
import type {CamelizedGradingPeriod} from '@canvas/grading/grading.d'
import type {Filter, FilterDrilldownData, FilterDrilldownMenuItem} from '../gradebook.d'
import type {AssignmentGroup, Module, Section, StudentGroupCategoryMap} from '../../../../../api.d'
import {getLabelForFilter, doFiltersMatch, isFilterNotEmpty} from '../Gradebook.utils'
import useStore from '../stores/index'
import FilterDropdown from './FilterDropdown'
import FilterNavDateModal from './FilterDateModal'
import FilterTray from './FilterTray'
import natcompare from '@canvas/util/natcompare'

const I18n = useI18nScope('gradebook')

const {Item: FlexItem} = Flex as any

export type FilterNavProps = {
  modules: Module[]
  assignmentGroups: AssignmentGroup[]
  sections: Section[]
  gradingPeriods: CamelizedGradingPeriod[]
  studentGroupCategories: StudentGroupCategoryMap
}

export default function FilterNav({
  assignmentGroups,
  gradingPeriods,
  modules,
  sections,
  studentGroupCategories,
}: FilterNavProps) {
  const [isTrayOpen, setIsTrayOpen] = useState(false)
  const [isDateModalOpen, setIsDateModalOpen] = useState(false)
  const filterPresets = useStore(state => state.filterPresets)
  const applyFilters = useStore(state => state.applyFilters)
  const addFilters = useStore(state => state.addFilters)
  const toggleFilter = useStore(state => state.toggleFilter)
  const appliedFilters = useStore(state => state.appliedFilters)

  const assignments = assignmentGroups.flatMap(ag => ag.assignments)
  const modulesWithGradeableAssignments = modules.filter(m =>
    assignments.some(a => a.grading_type !== 'not_graded' && a.module_ids.includes(m.id))
  )

  const handleClearFilters = () => {
    applyFilters([])
  }

  const activeFilterComponents = appliedFilters.filter(isFilterNotEmpty).map(filter => {
    const label = getLabelForFilter(
      filter,
      assignmentGroups,
      gradingPeriods,
      modules,
      sections,
      studentGroupCategories
    )
    return (
      <Tag
        data-testid="applied-filter-tag"
        key={`staged-filter-${filter.id}`}
        text={<AccessibleContent alt={I18n.t('Remove filter')}>{label}</AccessibleContent>}
        dismissible={true}
        onClick={() =>
          useStore.setState({
            appliedFilters: appliedFilters.filter(c => c.id !== filter.id),
          })
        }
        margin="0 xx-small 0 0"
      />
    )
  })

  const dataMap: FilterDrilldownData = {
    savedFilterPresets: {
      id: 'savedFilterPresets',
      parentId: null,
      name: I18n.t('Saved Filter Presets'),
      items: [],
    },
  }

  for (const filterPreset of filterPresets) {
    const item = {
      id: filterPreset.id,
      parentId: 'savedFilterPresets',
      name: filterPreset.name,
      isSelected: doFiltersMatch(appliedFilters, filterPreset.filters),
      onToggle: () => {
        if (doFiltersMatch(appliedFilters, filterPreset.filters)) {
          applyFilters([])
        } else {
          applyFilters(filterPreset.filters)
        }
      },
    }
    dataMap[filterPreset.id] = item
    dataMap.savedFilterPresets.items?.push(item)
  }

  const filterItems: FilterDrilldownData = {}

  if (sections.length > 0) {
    filterItems.sections = {
      id: 'sections',
      name: I18n.t('Sections'),
      parentId: 'savedFilterPresets',
      isSelected: appliedFilters.some(c => c.type === 'section'),
      items: sections.map(s => ({
        id: s.id,
        name: s.name,
        isSelected: appliedFilters.some(c => c.type === 'section' && c.value === s.id),
        onToggle: () => {
          const filter: Filter = {
            id: uuid.v4(),
            type: 'section',
            value: s.id,
            created_at: new Date().toISOString(),
          }
          toggleFilter(filter)
        },
      })),
    }
    dataMap.sections = filterItems.sections
  }

  if (modules.length > 0) {
    filterItems.modules = {
      id: 'modules',
      name: I18n.t('Modules'),
      parentId: 'savedFilterPresets',
      isSelected: appliedFilters.some(c => c.type === 'module'),
      items: modulesWithGradeableAssignments.map(m => ({
        id: m.id,
        name: m.name,
        isSelected: appliedFilters.some(c => c.type === 'module' && c.value === m.id),
        onToggle: () => {
          const filter: Filter = {
            id: uuid.v4(),
            type: 'module',
            value: m.id,
            created_at: new Date().toISOString(),
          }
          toggleFilter(filter)
        },
      })),
    }
    dataMap.modules = filterItems.modules
  }

  if (gradingPeriods.length > 0) {
    const gradingPeriodItems: FilterDrilldownMenuItem[] = gradingPeriods.map(a => ({
      id: a.id,
      name: a.title,
      isSelected: appliedFilters.some(c => c.type === 'grading-period' && c.value === a.id),
      onToggle: () => {
        const filter: Filter = {
          id: uuid.v4(),
          type: 'grading-period',
          value: a.id,
          created_at: new Date().toISOString(),
        }
        toggleFilter(filter)
      },
    }))
    filterItems['grading-periods'] = {
      id: 'grading-periods',
      name: I18n.t('Grading Periods'),
      parentId: 'savedFilterPresets',
      isSelected: appliedFilters.some(c => c.type === 'grading-period'),
      items: [
        {
          id: 'ALL_GRADING_PERIODS',
          name: I18n.t('All Grading Periods'),
          isSelected: appliedFilters.some(c => c.type === 'grading-period' && c.value === '0'),
          onToggle: () => {
            const filter: Filter = {
              id: uuid.v4(),
              type: 'grading-period',
              value: '0',
              created_at: new Date().toISOString(),
            }
            toggleFilter(filter)
          },
        } as FilterDrilldownMenuItem,
      ].concat(gradingPeriodItems),
      itemGroups: [],
    }
    dataMap['grading-periods'] = filterItems['grading-periods']
  }

  if (assignmentGroups.length > 1) {
    filterItems['assignment-groups'] = {
      id: 'assignment-groups',
      name: I18n.t('Assignment Groups'),
      parentId: 'savedFilterPresets',
      isSelected: appliedFilters.some(c => c.type === 'assignment-group'),
      items: assignmentGroups.map(a => ({
        id: a.id,
        name: a.name,
        isSelected: appliedFilters.some(c => c.type === 'assignment-group' && c.value === a.id),
        onToggle: () => {
          const filter: Filter = {
            id: uuid.v4(),
            type: 'assignment-group',
            value: a.id,
            created_at: new Date().toISOString(),
          }
          toggleFilter(filter)
        },
      })),
      itemGroups: [],
    }
    dataMap['assignment-groups'] = filterItems['assignment-groups']
  }

  if (Object.values(studentGroupCategories).length > 0) {
    filterItems['student-groups'] = {
      id: 'student-groups',
      name: I18n.t('Student Groups'),
      parentId: 'savedFilterPresets',
      isSelected: appliedFilters.some(c => c.type === 'student-group'),
      itemGroups: Object.values(studentGroupCategories)
        .sort((c1, c2) => natcompare.strings(c1.name, c2.name))
        .map(category => ({
          id: category.id,
          name: category.name,
          items: category.groups
            .sort((g1, g2) => natcompare.strings(g1.name, g2.name))
            .map(group => ({
              id: group.id,
              name: group.name,
              isSelected: appliedFilters.some(
                c => c.type === 'student-group' && c.value === group.id
              ),
              onToggle: () => {
                const filter: Filter = {
                  id: uuid.v4(),
                  type: 'student-group',
                  value: group.id,
                  created_at: new Date().toISOString(),
                }
                toggleFilter(filter)
              },
            })),
        })),
    }
    dataMap['student-groups'] = filterItems['student-groups']
  }

  filterItems.submissions = {
    id: 'submissions',
    name: I18n.t('Submissions'),
    parentId: 'savedFilterPresets',
    isSelected: appliedFilters.some(c => c.type === 'submissions'),
    items: [
      {
        id: 'savedFilterPresets',
        name: 'Has Ungraded Submissions',
        isSelected: appliedFilters.some(
          c => c.type === 'submissions' && c.value === 'has-ungraded-submissions'
        ),
        onToggle: () => {
          const filter: Filter = {
            id: uuid.v4(),
            type: 'submissions',
            value: 'has-ungraded-submissions',
            created_at: new Date().toISOString(),
          }
          toggleFilter(filter)
        },
      },
      {
        id: '2',
        name: 'Has Submissions',
        isSelected: appliedFilters.some(
          c => c.type === 'submissions' && c.value === 'has-submissions'
        ),
        onToggle: () => {
          const filter: Filter = {
            id: uuid.v4(),
            type: 'submissions',
            value: 'has-submissions',
            created_at: new Date().toISOString(),
          }
          toggleFilter(filter)
        },
      },
    ],
  }
  dataMap.submissions = filterItems.submissions

  filterItems.startAndEndDate = {
    id: 'start-and-end-date',
    name: I18n.t('Start & End Date'),
    parentId: 'savedFilterPresets',
    isSelected: appliedFilters.some(
      f => (f.type === 'start-date' || f.type === 'end-date') && isFilterNotEmpty(f)
    ),
    onToggle: () => setIsDateModalOpen(true),
  }

  const startDate = appliedFilters.find((c: Filter) => c.type === 'start-date')?.value || null

  const endDate = appliedFilters.find((c: Filter) => c.type === 'end-date')?.value || null

  return (
    <Flex justifyItems="space-between" padding="0 0 small 0">
      <FlexItem>
        <Flex>
          <FlexItem padding="0 small 0 0">
            <FilterDropdown
              onOpenTray={() => setIsTrayOpen(true)}
              dataMap={dataMap}
              filterItems={filterItems}
            />
          </FlexItem>
          <FlexItem data-testid="filter-tags">
            {activeFilterComponents.length > 0 && activeFilterComponents}
          </FlexItem>
        </Flex>
      </FlexItem>

      <FlexItem>
        {activeFilterComponents.length > 0 && (
          <Link isWithinText={false} as="button" margin="0" onClick={handleClearFilters}>
            {I18n.t('Clear All Filters')}
          </Link>
        )}
      </FlexItem>

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
        onSelectDates={(startDateValue, endDateValue) => {
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

/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {useMemo} from 'react'
import uuid from 'uuid'
import useStore from '../stores/index'
import type {AssignmentGroup, Module, Section, StudentGroupCategoryMap} from '../../../../../api.d'
import type {CamelizedGradingPeriod} from '@canvas/grading/grading.d'
import {useScope as useI18nScope} from '@canvas/i18n'
import natcompare from '@canvas/util/natcompare'
import {
  doFiltersMatch,
  formatGradingPeriodTitleForDisplay,
  getCustomStatusIdStrings,
  isFilterNotEmpty,
  mapCustomStatusToIdString,
} from '../Gradebook.utils'
import type {
  Filter,
  FilterDrilldownData,
  FilterDrilldownMenuItem,
  FilterPreset,
} from '../gradebook.d'
import type {GradeStatus} from '@canvas/grading/accountGradingStatus'

const I18n = useI18nScope('gradebook')

function useFilterDropdownData({
  appliedFilters,
  assignmentGroups,
  filterPresets,
  gradingPeriods,
  modules,
  sections,
  studentGroupCategories,
  onToggleFilterPreset,
  onToggleDateModal,
  customStatuses,
  multiselectGradebookFiltersEnabled,
}: {
  appliedFilters: Filter[]
  assignmentGroups: AssignmentGroup[]
  filterPresets: FilterPreset[]
  gradingPeriods: CamelizedGradingPeriod[]
  modules: Module[]
  sections: Section[]
  studentGroupCategories: StudentGroupCategoryMap
  onToggleFilterPreset: (filterPreset: FilterPreset) => void
  onToggleDateModal: () => void
  customStatuses: GradeStatus[]
  multiselectGradebookFiltersEnabled?: boolean
}) {
  const assignments = assignmentGroups.flatMap(ag => ag.assignments)
  const modulesWithGradeableAssignments = useMemo(() => {
    return modules.filter(m =>
      assignments.some(a => a.grading_type !== 'not_graded' && (a.module_ids || []).includes(m.id))
    )
  }, [modules, assignments])
  const {toggleFilter, toggleFilterMultiSelect} = useStore.getState()
  const toggleFilterHelper = multiselectGradebookFiltersEnabled
    ? toggleFilterMultiSelect
    : toggleFilter

  const {dataMap_, filterItems_} = useMemo(() => {
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
        onToggle: () => onToggleFilterPreset(filterPreset),
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
        items: sections
          .sort((s1, s2) => natcompare.strings(s1.name, s2.name))
          .map(s => ({
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
              toggleFilterHelper(filter)
            },
          })),
      }
      dataMap.sections = filterItems.sections
    }

    if (modulesWithGradeableAssignments.length > 0) {
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
            toggleFilterHelper(filter)
          },
        })),
      }
      dataMap.modules = filterItems.modules
    }

    if (gradingPeriods.length > 0) {
      const gradingPeriodItems: FilterDrilldownMenuItem[] = gradingPeriods.map(a => ({
        id: a.id,
        name: formatGradingPeriodTitleForDisplay(a),
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
            toggleFilterHelper(filter)
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
                  toggleFilterHelper(filter)
                },
              })),
          })),
      }
      dataMap['student-groups'] = filterItems['student-groups']
    }
    const customStatusIdStrings = getCustomStatusIdStrings(customStatuses)
    filterItems.status = {
      id: 'status',
      name: I18n.t('Status'),
      parentId: 'savedFilterPresets',
      isSelected: appliedFilters.some(
        c =>
          c.type === 'submissions' &&
          [
            'late',
            'missing',
            'resubmitted',
            'dropped',
            'excused',
            'extended',
            ...customStatusIdStrings,
          ].includes(c.value || '')
      ),
      items: [
        {
          id: '1',
          name: I18n.t('Late'),
          isSelected: appliedFilters.some(c => c.type === 'submissions' && c.value === 'late'),
          onToggle: () => {
            const filter: Filter = {
              id: uuid.v4(),
              type: 'submissions',
              value: 'late',
              created_at: new Date().toISOString(),
            }
            toggleFilterHelper(filter)
          },
        },
        {
          id: '2',
          name: I18n.t('Missing'),
          isSelected: appliedFilters.some(c => c.type === 'submissions' && c.value === 'missing'),
          onToggle: () => {
            const filter: Filter = {
              id: uuid.v4(),
              type: 'submissions',
              value: 'missing',
              created_at: new Date().toISOString(),
            }
            toggleFilterHelper(filter)
          },
        },
        {
          id: '3',
          name: I18n.t('Resubmitted'),
          isSelected: appliedFilters.some(
            c => c.type === 'submissions' && c.value === 'resubmitted'
          ),
          onToggle: () => {
            const filter: Filter = {
              id: uuid.v4(),
              type: 'submissions',
              value: 'resubmitted',
              created_at: new Date().toISOString(),
            }
            toggleFilterHelper(filter)
          },
        },
        {
          id: '4',
          name: I18n.t('Dropped'),
          isSelected: appliedFilters.some(c => c.type === 'submissions' && c.value === 'dropped'),
          onToggle: () => {
            const filter: Filter = {
              id: uuid.v4(),
              type: 'submissions',
              value: 'dropped',
              created_at: new Date().toISOString(),
            }
            toggleFilterHelper(filter)
          },
        },
        {
          id: '5',
          name: I18n.t('Excused'),
          isSelected: appliedFilters.some(c => c.type === 'submissions' && c.value === 'excused'),
          onToggle: () => {
            const filter: Filter = {
              id: uuid.v4(),
              type: 'submissions',
              value: 'excused',
              created_at: new Date().toISOString(),
            }
            toggleFilterHelper(filter)
          },
        },
      ],
    }
    if (ENV.FEATURES.extended_submission_state) {
      filterItems.status.items!.push({
        id: '6',
        name: I18n.t('Extended'),
        isSelected: appliedFilters.some(c => c.type === 'submissions' && c.value === 'extended'),
        onToggle: () => {
          const filter: Filter = {
            id: uuid.v4(),
            type: 'submissions',
            value: 'extended',
            created_at: new Date().toISOString(),
          }
          toggleFilterHelper(filter)
        },
      })
    }
    customStatuses.forEach(status => {
      filterItems.status.items!.push({
        id: mapCustomStatusToIdString(status),
        name: status.name,
        isSelected: appliedFilters.some(
          c => c.type === 'submissions' && c.value === mapCustomStatusToIdString(status)
        ),
        onToggle: () => {
          const filter: Filter = {
            id: uuid.v4(),
            type: 'submissions',
            value: mapCustomStatusToIdString(status),
            created_at: new Date().toISOString(),
          }
          toggleFilterHelper(filter)
        },
      })
    })
    dataMap.status = filterItems.status

    filterItems.submissions = {
      id: 'submissions',
      name: I18n.t('Submissions'),
      parentId: 'savedFilterPresets',
      isSelected: appliedFilters.some(
        c =>
          c.type === 'submissions' &&
          [
            'has-ungraded-submissions',
            'has-submissions',
            'has-no-submissions',
            'has-unposted-grades',
          ].includes(c.value || '')
      ),
      items: [
        {
          id: '1',
          name: I18n.t('Has Ungraded Submissions'),
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
            toggleFilterHelper(filter)
          },
        },
        {
          id: '2',
          name: I18n.t('Has Submissions'),
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
            toggleFilterHelper(filter)
          },
        },
        {
          id: '3',
          name: I18n.t('Has No Submissions'),
          isSelected: appliedFilters.some(
            c => c.type === 'submissions' && c.value === 'has-no-submissions'
          ),
          onToggle: () => {
            const filter: Filter = {
              id: uuid.v4(),
              type: 'submissions',
              value: 'has-no-submissions',
              created_at: new Date().toISOString(),
            }
            toggleFilterHelper(filter)
          },
        },
        {
          id: '4',
          name: I18n.t('Has Unposted Grades'),
          isSelected: appliedFilters.some(
            c => c.type === 'submissions' && c.value === 'has-unposted-grades'
          ),
          onToggle: () => {
            const filter: Filter = {
              id: uuid.v4(),
              type: 'submissions',
              value: 'has-unposted-grades',
              created_at: new Date().toISOString(),
            }
            toggleFilterHelper(filter)
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
      onToggle: onToggleDateModal,
    }

    return {dataMap_: dataMap, filterItems_: filterItems}
  }, [
    appliedFilters,
    assignmentGroups,
    customStatuses,
    filterPresets,
    gradingPeriods,
    modulesWithGradeableAssignments,
    onToggleDateModal,
    onToggleFilterPreset,
    sections,
    studentGroupCategories,
    toggleFilter,
    toggleFilterHelper,
  ])

  return {dataMap: dataMap_, filterItems: filterItems_}
}

export {useFilterDropdownData}

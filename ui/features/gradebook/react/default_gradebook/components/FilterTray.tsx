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

import React from 'react'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Tray} from '@instructure/ui-tray'
import {IconFilterLine} from '@instructure/ui-icons'
import {useScope as useI18nScope} from '@canvas/i18n'
import {View, ContextView} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import FilterTrayPreset from './FilterTrayFilterPreset'
import useStore from '../stores/index'
import uuid from 'uuid'
import {doFiltersMatch} from '../Gradebook.utils'
import type {
  Filter,
  FilterPreset,
  Module,
  AssignmentGroup,
  Section,
  GradingPeriod,
  StudentGroupCategoryMap
} from '../gradebook.d'

const {Item: FlexItem} = Flex as any

const I18n = useI18nScope('gradebook')

export type FilterTrayProps = {
  isTrayOpen: any
  setIsTrayOpen: (isOpen: boolean) => void
  filterPresets: FilterPreset[]
  modules: Module[]
  assignmentGroups: AssignmentGroup[]
  sections: Section[]
  gradingPeriods: GradingPeriod[]
  studentGroupCategories: StudentGroupCategoryMap
}

export default function FilterNavTray({
  isTrayOpen,
  setIsTrayOpen,
  filterPresets,
  assignmentGroups,
  modules,
  gradingPeriods,
  sections,
  studentGroupCategories
}: FilterTrayProps) {
  const stagedFilters = useStore(state => state.stagedFilters)
  const saveStagedFilter = useStore(state => state.saveStagedFilter)
  const updateFilterPreset = useStore(state => state.updateFilterPreset)
  const deleteFilterPreset = useStore(state => state.deleteFilterPreset)
  const deleteStagedFilter = useStore(state => state.deleteStagedFilter)
  const applyFilters = useStore(state => state.applyFilters)
  const appliedFilters = useStore(state => state.appliedFilters)

  const initialFilters: Filter[] = [
    {
      id: uuid(),
      type: 'section',
      value: undefined,
      created_at: new Date().toISOString()
    },
    {
      id: uuid(),
      type: 'module',
      value: undefined,
      created_at: new Date().toISOString()
    },
    {
      id: uuid(),
      type: 'assignment-group',
      value: undefined,
      created_at: new Date().toISOString()
    },
    {
      id: uuid(),
      type: 'student-group',
      value: undefined,
      created_at: new Date().toISOString()
    },
    {
      id: uuid(),
      type: 'grading-period',
      value: undefined,
      created_at: new Date().toISOString()
    },
    {
      id: uuid(),
      type: 'submissions',
      value: undefined,
      created_at: new Date().toISOString()
    },
    {
      id: uuid(),
      type: 'start-date',
      value: undefined,
      created_at: new Date().toISOString()
    },
    {
      id: uuid(),
      type: 'end-date',
      value: undefined,
      created_at: new Date().toISOString()
    }
  ]

  return (
    <Tray
      placement="end"
      label="Tray Example"
      open={isTrayOpen}
      onDismiss={() => setIsTrayOpen(false)}
      size="regular"
      shouldCloseOnDocumentClick={true}
    >
      <View as="div" padding="medium">
        <Flex>
          <FlexItem shouldGrow={true} shouldShrink={true}>
            <Heading level="h3" as="h3" margin="0 0 x-small">
              {I18n.t('Gradebook Filter Presets')}
            </Heading>
          </FlexItem>
          <FlexItem>
            <CloseButton
              placement="end"
              offset="small"
              screenReaderLabel="Close"
              onClick={() => setIsTrayOpen(false)}
            />
          </FlexItem>
        </Flex>

        {filterPresets.length === 0 && !stagedFilters.length && (
          <Flex as="div" margin="small">
            <FlexItem display="inline-block" width="100px" height="128px">
              <img
                src="/images/tutorial-tray-images/Panda_People.svg"
                alt={I18n.t('Friendly panda')}
                style={{
                  width: '100px',
                  height: '128px'
                }}
              />
            </FlexItem>
            <FlexItem shouldShrink>
              <ContextView
                padding="x-small small"
                margin="small"
                placement="end top"
                shadow="resting"
              >
                {I18n.t(
                  'Did you know you can now create filter presets and save them for future use?'
                )}
              </ContextView>
            </FlexItem>
          </Flex>
        )}

        {filterPresets.map(filterPreset => (
          <FilterTrayPreset
            applyFilters={applyFilters}
            assignmentGroups={assignmentGroups}
            filterPreset={filterPreset}
            isActive={doFiltersMatch(appliedFilters, filterPreset.filters)}
            gradingPeriods={gradingPeriods}
            key={filterPreset.id}
            modules={modules}
            onUpdate={updateFilterPreset}
            onDelete={() => deleteFilterPreset(filterPreset)}
            sections={sections}
            studentGroupCategories={studentGroupCategories}
          />
        ))}
        <View as="div">
          {stagedFilters.length > 0 ? (
            <FilterTrayPreset
              applyFilters={applyFilters}
              assignmentGroups={assignmentGroups}
              filterPreset={{
                name: '',
                filters: stagedFilters,
                created_at: new Date().toISOString()
              }}
              isActive={doFiltersMatch(appliedFilters, stagedFilters)}
              gradingPeriods={gradingPeriods}
              key="staged"
              modules={modules}
              onCreate={saveStagedFilter}
              onDelete={deleteStagedFilter}
              sections={sections}
              studentGroupCategories={studentGroupCategories}
            />
          ) : (
            <Button
              renderIcon={IconFilterLine}
              color="secondary"
              onClick={() =>
                useStore.setState({
                  stagedFilters: initialFilters
                })
              }
              margin="x-small 0 0 0"
              data-testid="new-filter-button"
            >
              {I18n.t('Create New Filter Preset')}
            </Button>
          )}
        </View>
      </View>
    </Tray>
  )
}

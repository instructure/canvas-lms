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
import {CloseButton} from '@instructure/ui-buttons'
import {Tray} from '@instructure/ui-tray'
import {useScope as useI18nScope} from '@canvas/i18n'
import {View, ContextView} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import FilterTrayPreset from './FilterTrayFilterPreset'
import useStore from '../stores/index'

import {doFiltersMatch} from '../Gradebook.utils'
import type {CamelizedGradingPeriod} from '@canvas/grading/grading.d'
import type {FilterPreset, PartialFilterPreset} from '../gradebook.d'
import type {AssignmentGroup, Module, Section, StudentGroupCategory} from '../../../../../api.d'

const {Item: FlexItem} = Flex as any

const I18n = useI18nScope('gradebook')

export type FilterTrayProps = {
  isTrayOpen: boolean
  setIsTrayOpen: (isOpen: boolean) => void
  filterPresets: FilterPreset[]
  modules: Module[]
  assignmentGroups: AssignmentGroup[]
  sections: Section[]
  gradingPeriods: CamelizedGradingPeriod[]
  studentGroupCategories: StudentGroupCategory[]
}

export default function FilterTray({
  isTrayOpen,
  setIsTrayOpen,
  filterPresets,
  assignmentGroups,
  modules,
  gradingPeriods,
  sections,
  studentGroupCategories
}: FilterTrayProps) {
  const saveStagedFilter = useStore(state => state.saveStagedFilter)
  const updateFilterPreset = useStore(state => state.updateFilterPreset)
  const deleteFilterPreset = useStore(state => state.deleteFilterPreset)
  const applyFilters = useStore(state => state.applyFilters)
  const appliedFilters = useStore(state => state.appliedFilters)
  const [expandedFilterPresetId, setExpandedFilterPresetId] = useState<string | null>(null)

  return (
    <Tray
      placement="end"
      label="Tray Example"
      open={isTrayOpen}
      onDismiss={() => {
        setIsTrayOpen(false)
        setExpandedFilterPresetId(null)
      }}
      size="regular"
      shouldCloseOnDocumentClick={true}
    >
      <View as="div" padding="medium">
        <Flex margin="0 0 small 0">
          <FlexItem shouldGrow={true} shouldShrink={true}>
            <Heading level="h3" as="h3" margin="0 0 x-small">
              {I18n.t('Saved Filter Presets')}
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

        {filterPresets.length === 0 && (
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
            <FlexItem shouldShrink={true}>
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

        <View as="div" borderWidth="0 0 small 0" padding="0 0 medium 0">
          <FilterTrayPreset
            applyFilters={applyFilters}
            assignmentGroups={assignmentGroups}
            filterPreset={{
              name: '',
              filters: appliedFilters,
              created_at: new Date().toISOString(),
              updated_at: new Date().toISOString()
            }}
            isActive={true}
            gradingPeriods={gradingPeriods}
            modules={modules}
            onCreate={(filterPreset: PartialFilterPreset) => {
              saveStagedFilter(filterPreset)
              setExpandedFilterPresetId(null)
            }}
            onToggle={() =>
              setExpandedFilterPresetId(expandedFilterPresetId === 'new' ? null : 'new')
            }
            isExpanded={expandedFilterPresetId === 'new'}
            sections={sections}
            studentGroupCategories={studentGroupCategories}
          />
        </View>

        <View as="div" margin="medium 0 0 0">
          {filterPresets.map(filterPreset => (
            <View as="div" margin="0 0 small 0">
              <FilterTrayPreset
                key={filterPreset.id}
                applyFilters={applyFilters}
                assignmentGroups={assignmentGroups}
                filterPreset={filterPreset}
                isActive={doFiltersMatch(appliedFilters, filterPreset.filters)}
                gradingPeriods={gradingPeriods}
                modules={modules}
                onUpdate={updateFilterPreset}
                onDelete={() => deleteFilterPreset(filterPreset)}
                onToggle={() =>
                  setExpandedFilterPresetId(
                    expandedFilterPresetId === filterPreset.id ? null : filterPreset.id
                  )
                }
                isExpanded={expandedFilterPresetId === filterPreset.id}
                sections={sections}
                studentGroupCategories={studentGroupCategories}
              />
            </View>
          ))}
        </View>
      </View>
    </Tray>
  )
}

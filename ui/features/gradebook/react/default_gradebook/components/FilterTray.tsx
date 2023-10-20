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
import type {AssignmentGroup, Module, Section, StudentGroupCategoryMap} from '../../../../../api.d'

const I18n = useI18nScope('gradebook')

export type FilterTrayProps = {
  isTrayOpen: boolean
  setIsTrayOpen: (isOpen: boolean) => void
  filterPresets: FilterPreset[]
  modules: Module[]
  assignmentGroups: AssignmentGroup[]
  sections: Section[]
  gradingPeriods: CamelizedGradingPeriod[]
  studentGroupCategories: StudentGroupCategoryMap
}

export default function FilterTray({
  isTrayOpen,
  setIsTrayOpen,
  filterPresets,
  assignmentGroups,
  modules,
  gradingPeriods,
  sections,
  studentGroupCategories,
}: FilterTrayProps) {
  const saveStagedFilter = useStore(state => state.saveStagedFilter)
  const stagedFilterPresetName = useStore(state => state.stagedFilterPresetName)
  const updateFilterPreset = useStore(state => state.updateFilterPreset)
  const deleteFilterPreset = useStore(state => state.deleteFilterPreset)
  const applyFilters = useStore(state => state.applyFilters)
  const appliedFilters = useStore(state => state.appliedFilters)
  const [expandedFilterPresetId, setExpandedFilterPresetId] = useState<string | null>(null)
  const closeRef = React.useRef<HTMLElement>()

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
          <Flex.Item shouldGrow={true} shouldShrink={true}>
            <Heading level="h3" as="h3" margin="0 0 x-small">
              {I18n.t('Saved Filter Presets')}
            </Heading>
          </Flex.Item>
          <Flex.Item>
            <CloseButton
              elementRef={ref => {
                if (ref instanceof HTMLElement) {
                  closeRef.current = ref
                }
              }}
              placement="end"
              offset="small"
              screenReaderLabel="Close"
              onClick={() => {
                setIsTrayOpen(false)
                setExpandedFilterPresetId(null)
              }}
            />
          </Flex.Item>
        </Flex>

        {filterPresets.length === 0 && (
          <Flex as="div" margin="small" display="inline-flex">
            <Flex.Item width="100px" height="128px">
              <img
                data-testid="friendly-panda"
                src="/images/tutorial-tray-images/Panda_People.svg"
                alt=""
                style={{
                  width: '100px',
                  height: '128px',
                }}
              />
            </Flex.Item>
            <Flex.Item shouldShrink={true}>
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
            </Flex.Item>
          </Flex>
        )}

        <View as="div" borderWidth="0 0 small 0" padding="0 0 medium 0">
          <FilterTrayPreset
            applyFilters={applyFilters}
            assignmentGroups={assignmentGroups}
            filterPreset={{
              name: stagedFilterPresetName,
              filters: appliedFilters,
              created_at: new Date().toISOString(),
              updated_at: new Date().toISOString(),
            }}
            isActive={true}
            closeRef={closeRef}
            gradingPeriods={gradingPeriods}
            modules={modules}
            onCreate={(filterPreset: PartialFilterPreset) => {
              setExpandedFilterPresetId(null)
              return saveStagedFilter(filterPreset).then(success => {
                if (success) {
                  setExpandedFilterPresetId(null)
                } else {
                  setExpandedFilterPresetId('new')
                }
                return success
              })
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
            <View as="div" margin="0 0 small 0" key={filterPreset.id}>
              <FilterTrayPreset
                applyFilters={applyFilters}
                assignmentGroups={assignmentGroups}
                filterPreset={filterPreset}
                gradingPeriods={gradingPeriods}
                closeRef={closeRef}
                isActive={doFiltersMatch(appliedFilters, filterPreset.filters)}
                isExpanded={expandedFilterPresetId === filterPreset.id}
                modules={modules}
                onDelete={() => deleteFilterPreset(filterPreset)}
                onToggle={() =>
                  setExpandedFilterPresetId(
                    expandedFilterPresetId === filterPreset.id ? null : filterPreset.id
                  )
                }
                onUpdate={updatedFilterPreset => {
                  setExpandedFilterPresetId(null)
                  return updateFilterPreset(updatedFilterPreset).then(success => {
                    if (success) {
                      setExpandedFilterPresetId(null)
                    } else {
                      setExpandedFilterPresetId(updatedFilterPreset.id)
                    }
                    return success
                  })
                }}
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

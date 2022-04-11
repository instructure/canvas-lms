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
import {Button, CloseButton} from '@instructure/ui-buttons'
import {AccessibleContent} from '@instructure/ui-a11y-content'
import uuid from 'uuid'
import {useScope as useI18nScope} from '@canvas/i18n'
import {IconFilterSolid, IconFilterLine} from '@instructure/ui-icons'
import {TextInput} from '@instructure/ui-text-input'
import {View, ContextView} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Tag} from '@instructure/ui-tag'
import {Tray} from '@instructure/ui-tray'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import FilterNavFilter from './FilterNavFilter'
import type {
  AssignmentGroup,
  Filter,
  GradingPeriod,
  Module,
  Section,
  StudentGroupCategoryMap
} from '../gradebook.d'
import {getLabelForFilterCondition, doFilterConditionsMatch} from '../Gradebook.utils'
import useStore from '../stores/index'

const I18n = useI18nScope('gradebook')

const {Item: FlexItem} = Flex as any

export type FilterNavProps = {
  modules: Module[]
  assignmentGroups: AssignmentGroup[]
  sections: Section[]
  gradingPeriods: GradingPeriod[]
  studentGroupCategories: StudentGroupCategoryMap
}

export default function FilterNav({
  assignmentGroups,
  gradingPeriods,
  modules,
  sections,
  studentGroupCategories
}: FilterNavProps) {
  const [isTrayOpen, setIsTrayOpen] = useState(false)
  const [stagedFilterName, setStagedFilterName] = useState('')
  const filters = useStore(state => state.filters)
  const stagedFilterConditions = useStore(state => state.stagedFilterConditions)
  const saveStagedFilter = useStore(state => state.saveStagedFilter)
  const updateFilter = useStore(state => state.updateFilter)
  const deleteFilter = useStore(state => state.deleteFilter)
  const applyConditions = useStore(state => state.applyConditions)
  const appliedFilterConditions = useStore(state => state.appliedFilterConditions)
  const updateStagedFilter = useStore(state => state.updateStagedFilter)
  const deleteStagedFilter = useStore(state => state.deleteStagedFilter)

  const filterComponents = appliedFilterConditions
    .filter(c => c.value)
    .map(condition => {
      const label = getLabelForFilterCondition(
        condition,
        assignmentGroups,
        gradingPeriods,
        modules,
        sections,
        studentGroupCategories
      )
      return (
        <Tag
          data-testid="staged-filter-condition-tag"
          key={`staged-condition-${condition.id}`}
          text={<AccessibleContent alt={I18n.t('Remove condition')}>{label}</AccessibleContent>}
          dismissible
          onClick={() =>
            useStore.setState({
              appliedFilterConditions: appliedFilterConditions.filter(c => c.id !== condition.id)
            })
          }
          margin="0 xx-small 0 0"
        />
      )
    })

  const handleSaveStagedFilter = async () => {
    await saveStagedFilter(stagedFilterName)
    setStagedFilterName('')
  }

  return (
    <Flex justifyItems="space-between" padding="0 0 small 0">
      <FlexItem>
        <Flex>
          <FlexItem padding="0 x-small 0 0">
            <IconFilterLine /> <Text weight="bold">{I18n.t('Applied Filters:')}</Text>
          </FlexItem>
          <FlexItem>
            {filterComponents.length > 0 && filterComponents}
            {!filterComponents.length && (
              <Text color="secondary" weight="bold">
                {I18n.t('None')}
              </Text>
            )}
          </FlexItem>
        </Flex>
      </FlexItem>
      <FlexItem>
        <Button renderIcon={IconFilterSolid} color="secondary" onClick={() => setIsTrayOpen(true)}>
          {I18n.t('Filters')}
        </Button>
      </FlexItem>
      <Tray
        placement="end"
        label="Tray Example"
        open={isTrayOpen}
        onDismiss={() => setIsTrayOpen(false)}
        size="regular"
        shouldCloseOnDocumentClick
      >
        <View as="div" padding="medium">
          <Flex>
            <FlexItem shouldGrow shouldShrink>
              <Heading level="h3" as="h3" margin="0 0 x-small">
                {I18n.t('Gradebook Filters')}
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

          {filters.length === 0 && !stagedFilterConditions.length && (
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
                    'Did you know you can now create detailed filters and save them for future use?'
                  )}
                </ContextView>
              </FlexItem>
            </Flex>
          )}

          {filters.map(filter => (
            <FilterNavFilter
              assignmentGroups={assignmentGroups}
              filter={filter}
              isApplied={doFilterConditionsMatch(appliedFilterConditions, filter.conditions)}
              gradingPeriods={gradingPeriods}
              key={filter.id}
              modules={modules}
              onChange={updateFilter}
              applyConditions={applyConditions}
              onDelete={() => deleteFilter(filter)}
              sections={sections}
              studentGroupCategories={studentGroupCategories}
            />
          ))}

          <View
            as="div"
            background="primary"
            padding="small none none none"
            borderWidth="small none none none"
          >
            {stagedFilterConditions.length > 0 ? (
              <>
                <FilterNavFilter
                  assignmentGroups={assignmentGroups}
                  filter={{
                    name: '',
                    conditions: stagedFilterConditions,
                    created_at: new Date().toISOString()
                  }}
                  isApplied={doFilterConditionsMatch(
                    appliedFilterConditions,
                    stagedFilterConditions
                  )}
                  gradingPeriods={gradingPeriods}
                  key="staged"
                  modules={modules}
                  applyConditions={applyConditions}
                  onChange={(filter: Filter) => updateStagedFilter(filter.conditions)}
                  onDelete={deleteStagedFilter}
                  sections={sections}
                  studentGroupCategories={studentGroupCategories}
                />
                <View as="div" padding="small" background="secondary" borderRadius="medium">
                  <Flex alignItems="end">
                    <FlexItem shouldGrow>
                      <TextInput
                        width="100%"
                        renderLabel={I18n.t('Save these conditions as a filter')}
                        placeholder={I18n.t('Give this filter a name')}
                        value={stagedFilterName}
                        onChange={(event: React.ChangeEvent<HTMLInputElement>) =>
                          setStagedFilterName(event.target.value)
                        }
                      />
                    </FlexItem>
                    <FlexItem margin="0 0 0 small">
                      <Button
                        color="secondary"
                        data-testid="save-filter-button"
                        margin="small 0 0 0"
                        onClick={handleSaveStagedFilter}
                        interaction={stagedFilterName.trim().length > 0 ? 'enabled' : 'disabled'}
                      >
                        {I18n.t('Save')}
                      </Button>
                    </FlexItem>
                  </Flex>
                </View>
              </>
            ) : (
              <Button
                renderIcon={IconFilterLine}
                color="secondary"
                onClick={() =>
                  useStore.setState({
                    stagedFilterConditions: [
                      {
                        id: uuid(),
                        type: undefined,
                        value: undefined,
                        created_at: new Date().toISOString()
                      }
                    ]
                  })
                }
                margin="small 0 0 0"
                data-testid="new-filter-button"
              >
                {I18n.t('Create New Filter')}
              </Button>
            )}
          </View>
        </View>
      </Tray>
    </Flex>
  )
}

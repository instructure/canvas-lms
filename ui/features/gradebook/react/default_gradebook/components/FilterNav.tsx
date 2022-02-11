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
// @ts-ignore
import I18n from 'i18n!gradebook'
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
  PartialFilter,
  Section
} from '../gradebook.d'
import useStore from '../stores/index'

const {Item: FlexItem} = Flex as any

export type FilterNavProps = {
  modules: Module[]
  assignmentGroups: AssignmentGroup[]
  sections: Section[]
  gradingPeriods: GradingPeriod[]
}

const newFilter = (): PartialFilter => ({
  name: '',
  conditions: [
    {
      id: uuid(),
      type: undefined,
      value: undefined,
      created_at: new Date().toISOString()
    }
  ],
  is_applied: false,
  created_at: new Date().toISOString()
})

export default function FilterNav({
  modules,
  assignmentGroups,
  gradingPeriods,
  sections
}: FilterNavProps) {
  const [isTrayOpen, setIsTrayOpen] = useState(false)
  const filters = useStore(state => state.filters)
  const stagedFilter = useStore(state => state.stagedFilter)
  const saveStagedFilter = useStore(state => state.saveStagedFilter)
  const updateFilter = useStore(state => state.updateFilter)
  const deleteFilter = useStore(state => state.deleteFilter)
  const filterComponents = filters
    .filter(f => f.is_applied)
    .map(filter => {
      return (
        <Tag
          key={filter.id}
          text={<AccessibleContent alt={I18n.t('Remove filter')}>{filter.name}</AccessibleContent>}
          dismissible
          onClick={() => deleteFilter(filter)}
          margin="0 xx-small 0 0"
        />
      )
    })

  return (
    <Flex justifyItems="space-between" padding="0 0 small 0">
      <FlexItem>
        <Flex>
          <FlexItem padding="0 x-small 0 0">
            <IconFilterLine /> <Text weight="bold">{I18n.t('Applied Filters:')}</Text>
          </FlexItem>
          <FlexItem>
            {filterComponents.length > 0 && filterComponents}
            {!filterComponents.length && !stagedFilter && (
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

          {filters.length === 0 && !stagedFilter && (
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
              key={filter.id}
              filter={filter}
              onChange={(f: Filter) => updateFilter(f)}
              onDelete={() => deleteFilter(filter)}
              modules={modules}
              assignmentGroups={assignmentGroups}
              sections={sections}
              gradingPeriods={gradingPeriods}
            />
          ))}

          <View
            as="div"
            background="primary"
            padding="small none none none"
            borderWidth="small none none none"
          >
            {stagedFilter ? (
              <>
                <FilterNavFilter
                  key="staged"
                  filter={stagedFilter}
                  onChange={(f: PartialFilter) => useStore.setState({stagedFilter: f})}
                  onDelete={() => useStore.setState({stagedFilter: null})}
                  modules={modules}
                  assignmentGroups={assignmentGroups}
                  sections={sections}
                  gradingPeriods={gradingPeriods}
                />
                <View as="div" padding="small" background="secondary" borderRadius="medium">
                  <Flex alignItems="end">
                    <FlexItem shouldGrow>
                      <TextInput
                        width="100%"
                        renderLabel={I18n.t('Save these conditions as a filter')}
                        placeholder={I18n.t('Give this filter a name')}
                        value={stagedFilter.name}
                        onChange={(event: React.ChangeEvent<HTMLInputElement>) =>
                          useStore.setState({
                            stagedFilter: {
                              ...stagedFilter,
                              name: event.target.value
                            }
                          })
                        }
                      />
                    </FlexItem>
                    <FlexItem margin="0 0 0 small">
                      <Button
                        color="secondary"
                        data-testid="save-filter-button"
                        margin="small 0 0 0"
                        onClick={saveStagedFilter}
                        interaction={stagedFilter.name.trim().length > 0 ? 'enabled' : 'disabled'}
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
                onClick={() => useStore.setState({stagedFilter: newFilter()})}
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

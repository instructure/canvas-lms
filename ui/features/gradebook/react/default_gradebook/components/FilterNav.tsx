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
import uuid from 'uuid'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {AccessibleContent} from '@instructure/ui-a11y-content'
// @ts-ignore
import I18n from 'i18n!gradebook'
import {IconFilterSolid, IconFilterLine} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Tag} from '@instructure/ui-tag'
import {Tray} from '@instructure/ui-tray'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import FilterNavFilter from './FilterNavFilter'

const {Item} = Flex as any

type FilterCondition = {
  id: string
  type?: string
  value?: string
  createdAt: string
}

type Filter = {
  id: string
  label?: string
  conditions: FilterCondition[]
  isApplied: boolean
  createdAt: string
}

type Module = {
  id: string
  name: string
}

type Section = {
  id: string
  name: string
}

type AssignmentGroup = {
  id: string
  name: string
}

type Props = {
  filters: Filter[]
  modules: Module[]
  assignmentGroups: AssignmentGroup[]
  sections: Section[]
  onChange: (filters: Filter[]) => void
}

export default function FilterNav({filters, modules, assignmentGroups, sections, onChange}: Props) {
  const [isTrayOpen, setIsTrayOpen] = useState(false)

  const openTray = () => {
    setIsTrayOpen(true)
  }

  const onCreateNewFilter = () => {
    onChange(
      filters.concat({
        id: uuid(),
        label: I18n.t('Unnamed Filter'),
        conditions: [
          {
            id: uuid(),
            type: undefined,
            value: undefined,
            createdAt: new Date().toISOString()
          }
        ],
        isApplied: true,
        createdAt: new Date().toISOString()
      })
    )
  }

  const onRemoveFilter = filter => {
    onChange(filters.filter(x => x !== filter))
  }

  const onChangeFilter = filter => {
    const newFilters = filters
      .filter(x => x.id !== filter.id)
      .concat(filter)
      .sort((a, b) => (a.createdAt < b.createdAt ? -1 : 1))
    onChange(newFilters)
  }

  const filterComponents = filters
    .filter(f => f.isApplied)
    .map(filter => {
      return (
        <Tag
          key={filter.id}
          text={<AccessibleContent alt={I18n.t('Remove filter')}>{filter.label}</AccessibleContent>}
          dismissible
          onClick={() => onRemoveFilter(filter)}
          margin="0 xx-small 0 0"
        />
      )
    })

  return (
    <Flex justifyItems="space-between" padding="0 0 small 0">
      <Item>
        <Flex>
          <Item padding="0 x-small 0 0">
            <IconFilterLine /> <Text weight="bold">{I18n.t('Applied Filters:')}</Text>
          </Item>
          <Item>
            {filterComponents.length > 0 ? (
              filterComponents
            ) : (
              <Text color="secondary" weight="bold">
                {I18n.t('None')}
              </Text>
            )}
          </Item>
        </Flex>
      </Item>
      <Item>
        <Button renderIcon={IconFilterSolid} color="secondary" onClick={openTray}>
          {I18n.t('Filters')}
        </Button>
      </Item>
      <Tray
        placement="end"
        label="Tray Example"
        open={isTrayOpen}
        onDismiss={() => setIsTrayOpen(false)}
        size="regular"
      >
        <View as="div" padding="medium">
          <Flex>
            <Item shouldGrow shouldShrink>
              <Heading level="h3" as="h3" margin="0 0 x-small">
                {I18n.t('Gradebook Filters')}
              </Heading>
            </Item>
            <Item>
              <CloseButton
                placement="end"
                offset="small"
                screenReaderLabel="Close"
                onClick={() => setIsTrayOpen(false)}
              />
            </Item>
          </Flex>

          {filters.map(filter => (
            <FilterNavFilter
              key={filter.id}
              filter={filter}
              onChange={filter_ => {
                onChangeFilter(filter_)
              }}
              onDelete={() => onRemoveFilter(filter)}
              modules={modules}
              assignmentGroups={assignmentGroups}
              sections={sections}
            />
          ))}

          <View
            as="div"
            background="primary"
            padding="small none none none"
            borderWidth="small none none none"
          >
            <Button
              renderIcon={IconFilterLine}
              color="secondary"
              onClick={onCreateNewFilter}
              margin="small 0 0 0"
              data-testid="new-filter-button"
            >
              {I18n.t('Create New Filter')}
            </Button>
          </View>
        </View>
      </Tray>
    </Flex>
  )
}

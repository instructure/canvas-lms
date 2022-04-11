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

import React, {useState, useRef, useEffect} from 'react'
import uuid from 'uuid'
import {useScope as useI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Button, IconButton} from '@instructure/ui-buttons'
import {Tooltip} from '@instructure/ui-tooltip'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {
  IconTrashLine,
  IconAddLine,
  IconXLine,
  IconEditLine,
  IconCheckDarkLine
} from '@instructure/ui-icons'
import {TextInput} from '@instructure/ui-text-input'
import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import Condition from './FilterNavCondition'
import type {
  AssignmentGroup,
  GradingPeriod,
  Module,
  PartialFilter,
  Filter,
  Section,
  StudentGroupCategoryMap
} from '../gradebook.d'
import filterConditionTypes from '../constants/filterConditionTypes'

const I18n = useI18nScope('gradebook')

const {Item} = Flex as any

export type FilterNavFilterProps = {
  applyConditions: (conditions: PartialFilter['conditions']) => void
  assignmentGroups: AssignmentGroup[]
  filter: PartialFilter | Filter
  gradingPeriods: GradingPeriod[]
  isApplied: boolean
  modules: Module[]
  onChange: any
  onDelete: any
  sections: Section[]
  studentGroupCategories: StudentGroupCategoryMap
}

export default function FilterNavFilter({
  applyConditions,
  assignmentGroups,
  filter,
  gradingPeriods,
  isApplied,
  modules,
  onChange,
  onDelete,
  sections,
  studentGroupCategories
}: FilterNavFilterProps) {
  const [isRenaming, setIsRenaming] = useState(false)
  const [wasRenaming, setWasRenaming] = useState(false)
  const [name, setName] = useState(filter.name)
  const inputRef = useRef<HTMLInputElement | null>(null)
  const renameButtonRef = useRef<HTMLElement | null>(null)

  useEffect(() => {
    if (isRenaming) {
      inputRef.current?.focus()
    } else if (wasRenaming) {
      renameButtonRef.current?.focus()
    }
  }, [isRenaming, wasRenaming])

  const onAddCondition = () => {
    const id: string = uuid.v4()
    onChange({
      ...filter,
      conditions: filter.conditions.concat({
        id,
        type: undefined,
        value: undefined,
        created_at: new Date().toISOString()
      })
    })
  }
  const onDeleteCondition = (condition_, divRef: React.RefObject<HTMLElement>) => {
    if (divRef.current?.previousElementSibling) {
      const buttons = Array.from(divRef.current.previousElementSibling.querySelectorAll('button'))
      const lastButton = buttons[buttons.length - 1]
      if (lastButton) {
        lastButton.focus()
      } else {
        throw new Error('expected button missing')
      }
    }
    onChange({
      ...filter,
      conditions: filter.conditions.filter(c => c.id !== condition_.id)
    })
  }
  const onChangeCondition = condition => {
    const otherConditions = filter.conditions.filter(c => c.id !== condition.id)
    if (otherConditions.find(c => c.type === condition.type)) {
      throw new Error('condition type already exists')
    }
    onChange({
      ...filter,
      conditions: filter.conditions
        .filter(c => c.id !== condition.id)
        .concat(condition)
        .sort((a, b) => (a.created_at < b.created_at ? -1 : 1))
    })
  }

  const toggleApply = () => {
    applyConditions(isApplied ? [] : filter.conditions)
  }

  return (
    <View as="div" padding="small 0">
      {filter.id && (
        <>
          {isRenaming ? (
            <Flex>
              <Item shouldGrow>
                <TextInput
                  inputRef={ref => (inputRef.current = ref)}
                  width="100%"
                  renderLabel={<ScreenReaderContent>{I18n.t('Name')}</ScreenReaderContent>}
                  placeholder={I18n.t('Name')}
                  value={name}
                  onChange={(_event, value) => setName(value)}
                />
              </Item>
              <Item>
                <IconButton
                  color="primary"
                  margin="0 x-small"
                  screenReaderLabel={I18n.t('Save label')}
                  onClick={() => {
                    onChange({
                      ...filter,
                      name: name || I18n.t('Untitled filter')
                    })
                    setIsRenaming(false)
                  }}
                >
                  <IconCheckDarkLine />
                </IconButton>
                <IconButton
                  screenReaderLabel={I18n.t('Cancel rename')}
                  onClick={() => {
                    setName(filter.name)
                    setIsRenaming(false)
                  }}
                >
                  <IconXLine />
                </IconButton>
              </Item>
            </Flex>
          ) : (
            <View as="div" data-testid={`filter-name-${filter.id}`}>
              {filter.name}
              <IconButton
                elementRef={el => (renameButtonRef.current = el)}
                color="primary"
                onClick={() => {
                  setIsRenaming(true)
                  setWasRenaming(true)
                }}
                screenReaderLabel={I18n.t('Rename filter')}
                withBackground={false}
                withBorder={false}
              >
                <IconEditLine />
              </IconButton>
            </View>
          )}
        </>
      )}

      {filter.conditions.map(condition => (
        <Condition
          assignmentGroups={assignmentGroups}
          condition={condition}
          conditionsInFilter={filter.conditions}
          gradingPeriods={gradingPeriods}
          key={condition.id}
          modules={modules}
          onChange={onChangeCondition}
          onDelete={onDeleteCondition}
          sections={sections}
          studentGroupCategories={studentGroupCategories}
        />
      ))}
      <Flex justifyItems="space-between">
        <Item>
          {filter.conditions.length < filterConditionTypes.length && (
            <Button
              color="primary"
              onClick={onAddCondition}
              renderIcon={IconAddLine}
              size="small"
              withBackground={false}
            >
              {I18n.t('Add Condition')}
            </Button>
          )}
        </Item>

        <Item>
          <Flex>
            <Item>
              <Checkbox
                checked={isApplied}
                label={I18n.t('Apply conditions')}
                labelPlacement="start"
                onChange={toggleApply}
                size="small"
                value="small"
                variant="toggle"
              />
            </Item>
            <Item>
              <Tooltip
                renderTip={I18n.t('Delete filter')}
                placement="bottom"
                on={['hover', 'focus']}
              >
                <IconButton
                  withBackground={false}
                  withBorder={false}
                  screenReaderLabel={I18n.t('Delete filter')}
                  onClick={onDelete}
                >
                  <IconTrashLine />
                </IconButton>
              </Tooltip>
            </Item>
          </Flex>
        </Item>
      </Flex>
    </View>
  )
}

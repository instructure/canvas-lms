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
import {chunk} from 'lodash'
import {View} from '@instructure/ui-view'
import {IconButton} from '@instructure/ui-buttons'
import {Tooltip} from '@instructure/ui-tooltip'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {IconTrashLine, IconXLine, IconEditLine, IconCheckDarkLine} from '@instructure/ui-icons'
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
  FilterCondition,
  FilterConditionType,
  Section,
  StudentGroupCategoryMap
} from '../gradebook.d'

const I18n = useI18nScope('gradebook')

const {Item: FlexItem} = Flex as any

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

  const ensureCondition = (
    conditions: FilterCondition[],
    type: FilterConditionType
  ): FilterCondition => {
    return (
      filter.conditions.find(condition => condition.type === type) || {
        id: uuid.v4(),
        type,
        value: undefined,
        created_at: new Date().toISOString()
      }
    )
  }

  const sectionCondition =
    sections.length > 0 ? ensureCondition(filter.conditions, 'section') : undefined

  const moduleCondition =
    modules.length > 0 ? ensureCondition(filter.conditions, 'module') : undefined

  const assignmentGroupCondition =
    assignmentGroups.length > 0 ? ensureCondition(filter.conditions, 'assignment-group') : undefined

  const studentGroupCondition =
    studentGroupCategories.length > 0
      ? ensureCondition(filter.conditions, 'student-group')
      : undefined

  // make the order of conditions consistent
  const conditionsWithItemsChunks = chunk(
    [sectionCondition, moduleCondition, assignmentGroupCondition, studentGroupCondition].filter(
      x => x
    ) as FilterCondition[],
    2
  )

  const gradingPeriodCondition = ensureCondition(filter.conditions, 'grading-period')
  const submissionCondition = ensureCondition(filter.conditions, 'submissions')
  const startDateCondition = ensureCondition(filter.conditions, 'start-date')
  const endDateCondition = ensureCondition(filter.conditions, 'end-date')

  const conditionsAlwaysShownChunks = [
    [gradingPeriodCondition, submissionCondition],
    [startDateCondition, endDateCondition]
  ]

  // console.debug('conditionsWithItemsChunks', conditionsWithItemsChunks)
  // console.debug('conditionsAlwaysShownChunks', conditionsAlwaysShownChunks)

  return (
    <View as="div" padding="small 0">
      {filter.id && (
        <>
          {isRenaming ? (
            <Flex>
              <FlexItem shouldGrow>
                <TextInput
                  inputRef={ref => (inputRef.current = ref)}
                  width="100%"
                  renderLabel={<ScreenReaderContent>{I18n.t('Name')}</ScreenReaderContent>}
                  placeholder={I18n.t('Name')}
                  value={name}
                  onChange={(_event, value) => setName(value)}
                />
              </FlexItem>
              <FlexItem>
                <IconButton
                  color="primary"
                  data-testid="save-label"
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
              </FlexItem>
            </Flex>
          ) : (
            <View as="div" data-testid={`filter-name-${filter.id}`}>
              {filter.name}
              <IconButton
                data-testid="rename-filter"
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

      {conditionsWithItemsChunks.map((conditions, index) => (
        // eslint-disable-next-line react/no-array-index-key
        <Flex justifyItems="space-between" margin="0 0 medium 0" key={`chunk-${index}`}>
          {conditions.map(condition => (
            <FlexItem key={condition.id}>
              <Condition
                assignmentGroups={assignmentGroups}
                condition={condition}
                gradingPeriods={gradingPeriods}
                modules={modules}
                onChange={onChangeCondition}
                sections={sections}
                studentGroupCategories={studentGroupCategories}
              />
            </FlexItem>
          ))}
        </Flex>
      ))}

      {conditionsAlwaysShownChunks.map((conditions, index) => (
        // eslint-disable-next-line react/no-array-index-key
        <Flex justifyItems="space-between" margin="0 0 medium 0" key={`chunk-${index}`}>
          {conditions.map(condition => (
            <FlexItem key={condition.id}>
              <Condition
                assignmentGroups={assignmentGroups}
                condition={condition}
                gradingPeriods={gradingPeriods}
                modules={modules}
                onChange={onChangeCondition}
                sections={sections}
                studentGroupCategories={studentGroupCategories}
              />
            </FlexItem>
          ))}
        </Flex>
      ))}

      <Flex justifyItems="end">
        <FlexItem>
          <Checkbox
            checked={isApplied}
            label={I18n.t('Apply conditions')}
            labelPlacement="start"
            onChange={toggleApply}
            size="small"
            value="small"
            variant="toggle"
          />
        </FlexItem>
        <FlexItem>
          <Tooltip renderTip={I18n.t('Delete filter')} placement="bottom" on={['hover', 'focus']}>
            <IconButton
              data-testid="delete-filter"
              withBackground={false}
              withBorder={false}
              screenReaderLabel={I18n.t('Delete filter')}
              onClick={onDelete}
            >
              <IconTrashLine />
            </IconButton>
          </Tooltip>
        </FlexItem>
      </Flex>
    </View>
  )
}

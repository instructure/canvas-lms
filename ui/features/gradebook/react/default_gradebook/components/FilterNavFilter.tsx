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
// @ts-ignore
import I18n from 'i18n!gradebook'
import {View} from '@instructure/ui-view'
import {Button, IconButton} from '@instructure/ui-buttons'
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

const {Item} = Flex as any

export default function FilterNavFilter({
  filter,
  onDelete,
  onChange,
  modules,
  assignmentGroups,
  sections
}) {
  const [isRenaming, setIsRenaming] = useState(false)
  const [label, setLabel] = useState(filter.label)
  const inputRef = useRef<HTMLInputElement | null>(null)

  useEffect(() => {
    if (inputRef.current instanceof HTMLInputElement && isRenaming) {
      inputRef.current.focus()
    }
  }, [isRenaming])

  const onAddCondition = () => {
    onChange({
      ...filter,
      conditions: filter.conditions.concat({
        id: uuid(),
        type: null,
        value: null,
        createdAt: new Date().toISOString()
      })
    })
  }
  const onDeleteCondition = condition => {
    onChange({
      ...filter,
      conditions: filter.conditions.filter(c => c.id !== condition.id)
    })
  }
  const onChangeCondition = condition => {
    onChange({
      ...filter,
      conditions: filter.conditions
        .filter(c => c.id !== condition.id)
        .concat(condition)
        .sort((a, b) => (a.createdAt < b.createdAt ? -1 : 1))
    })
  }

  const toggleApply = () => {
    onChange({
      ...filter,
      isApplied: !filter.isApplied
    })
  }

  return (
    <View as="div" padding="small 0">
      {isRenaming ? (
        <Flex>
          <Item shouldGrow>
            <TextInput
              inputRef={ref => (inputRef.current = ref)}
              width="100%"
              renderLabel={<ScreenReaderContent>{I18n.t('Name')}</ScreenReaderContent>}
              placeholder={I18n.t('Name')}
              value={label}
              onChange={(_event, value) => {
                setLabel(value)
              }}
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
                  label: label || I18n.t('Untitled filter')
                })
                setIsRenaming(false)
              }}
            >
              <IconCheckDarkLine />
            </IconButton>
            <IconButton
              screenReaderLabel={I18n.t('Cancel rename')}
              onClick={() => {
                setLabel(filter.label)
                setIsRenaming(false)
              }}
            >
              <IconXLine />
            </IconButton>
          </Item>
        </Flex>
      ) : (
        <View as="div">
          {filter.label}
          <IconButton
            color="primary"
            onClick={() => setIsRenaming(true)}
            screenReaderLabel={I18n.t('Rename filter')}
            withBackground={false}
            withBorder={false}
          >
            <IconEditLine />
          </IconButton>
        </View>
      )}

      {filter.conditions.map(condition => (
        <Condition
          key={condition.id}
          condition={condition}
          conditionsInFilter={filter.conditions}
          onChange={onChangeCondition}
          onDelete={onDeleteCondition}
          modules={modules}
          assignmentGroups={assignmentGroups}
          sections={sections}
        />
      ))}

      <Flex justifyItems="space-between">
        <Item>
          <Button
            color="primary"
            onClick={onAddCondition}
            renderIcon={IconAddLine}
            size="small"
            withBackground={false}
          >
            {I18n.t('Add Condition')}
          </Button>
        </Item>

        <Item>
          <Flex>
            <Item>
              <Checkbox
                checked={filter.isApplied}
                label={I18n.t('Apply filter')}
                labelPlacement="start"
                onChange={toggleApply}
                size="small"
                value="small"
                variant="toggle"
              />
            </Item>
            <Item>
              <IconButton
                withBackground={false}
                withBorder={false}
                screenReaderLabel={I18n.t('Delete filter')}
                onClick={onDelete}
              >
                <IconTrashLine />
              </IconButton>
            </Item>
          </Flex>
        </Item>
      </Flex>
    </View>
  )
}

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

import React, {Fragment, ComponentClass, useCallback, useState} from 'react'
import {Flex} from '@instructure/ui-flex'
// @ts-expect-error
import {Checkbox} from '@instructure/ui-checkbox'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('collapsable_list')

// @ts-expect-error
const FlexItem = Flex.Item as any

type ParentItem = {
  id: string
  label: string
  icon?: ComponentClass<{size: string}>
  children: [ChildItem]
}

type ChildItem = {
  id: string
  label: string
}

type SingleItem = {
  id: string
  label: string
  icon?: ComponentClass<{size: string}>
  children: [ChildItem]
}
type ParentItemCheckboxProps = {
  parentId: string
  label: string
  items: [ChildItem]
  icon?: ComponentClass<{size: string}>
  onChange: (ids: Set<string>) => void
}

type ChildItemCheckboxProps = {
  id: string
  label: string
  parentId: string
  selection: Set<string>
  onChange: (checked: boolean, id: string) => void
}

type SingleItemCheckboxProps = {
  id: string
  label: string
  icon?: ComponentClass<{size: string}>
  onChange: (selected: boolean) => void
}

export type CollapsableListProps = {
  items: [ParentItem]
  onChange: (selectedIds: string[]) => void
}

const ParentItemCheckbox = ({parentId, label, items, icon, onChange}: ParentItemCheckboxProps) => {
  const [selection, setSelection] = useState(new Set<string>())

  const isParentChecked = useCallback(() => {
    const checked = selection.has(parentId)
    const indeterminate = !checked && selection.size > 0 && selection.size < items.length
    return [checked, indeterminate]
  }, [parentId, selection, items.length])

  const cleanSelection = useCallback(() => {
    if (selection.has(parentId)) {
      // Delete all except parent id
      items.forEach(i => selection.delete(i.id))
    } else if (selection.size === items.length) {
      // Means all items are selected
      items.forEach(i => selection.delete(i.id))
      selection.add(parentId)
    }
  }, [parentId, selection, items])

  const handleItemCheck = useCallback(
    (checked: boolean, itemId: string) => {
      if (checked) {
        selection.add(itemId)
      } else if (selection.has(parentId) && itemId !== parentId) {
        selection.delete(parentId)
        items.forEach(i => itemId !== i.id && selection.add(i.id))
      } else {
        selection.delete(itemId)
      }
      cleanSelection()
      setSelection(selection)
      onChange(selection)
    },
    [items, parentId, selection, onChange, cleanSelection]
  )

  const [checked, indeterminate] = isParentChecked()
  const ParentIcon = icon

  return (
    <ToggleDetails
      data-testid={`toggle-${parentId}`}
      aria-label={I18n.t('%{label}, Navigate inside to interact with the checkbox', {label})}
      summary={
        <Flex>
          <FlexItem padding="x-small" shouldShrink={true}>
            <Checkbox
              checked={checked}
              indeterminate={indeterminate}
              // @ts-expect-error
              onChange={e => handleItemCheck(e.target.checked, parentId)}
              label={<ScreenReaderContent>{label}</ScreenReaderContent>}
              data-testid={`checkbox-${parentId}`}
            />
          </FlexItem>
          <FlexItem shouldShrink={true}>{ParentIcon && <ParentIcon size="small" />}</FlexItem>
          <FlexItem padding="0 small" shouldShrink={true}>
            <Text aria-hidden="true">{label}</Text>
          </FlexItem>
        </Flex>
      }
    >
      {items.map(item => (
        <ChildItemCheckbox
          key={item.id}
          id={item.id}
          label={item.label}
          parentId={parentId}
          selection={selection}
          onChange={handleItemCheck}
        />
      ))}
    </ToggleDetails>
  )
}

const ChildItemCheckbox = ({id, label, parentId, selection, onChange}: ChildItemCheckboxProps) => {
  return (
    <Flex margin="small 0 medium x-large">
      <FlexItem padding="0 xxx-small">
        <Checkbox
          checked={selection.has(id) || selection.has(parentId)}
          // @ts-expect-error
          onChange={e => onChange(e.target.checked, id)}
          label={
            <View padding="0 0 0 small">
              <Text>{label}</Text>
            </View>
          }
          data-testid={`checkbox-${id}`}
        />
      </FlexItem>
    </Flex>
  )
}

const SingleItemCheckbox = ({id, label, icon, onChange}: SingleItemCheckboxProps) => {
  const [checked, setChecked] = useState(false)
  const ParentIcon = icon

  const handleChecked = useCallback(
    (e: any) => {
      setChecked(e.target.checked)
      onChange(e.target.checked)
    },
    [onChange]
  )

  return (
    <Flex margin="x-small 0 x-small small" padding="0 0 0 xx-small">
      <FlexItem padding="x-small" shouldShrink={true}>
        <Checkbox
          checked={checked}
          onChange={handleChecked}
          label={<ScreenReaderContent>{label}</ScreenReaderContent>}
          data-testid={`checkbox-${id}`}
        />
      </FlexItem>
      <FlexItem shouldShrink={true}>{ParentIcon && <ParentIcon size="small" />}</FlexItem>
      <FlexItem padding="0 small" shouldShrink={true}>
        <Text aria-hidden="true">{label}</Text>
      </FlexItem>
    </Flex>
  )
}

export const CollapsableList = ({items, onChange}: CollapsableListProps) => {
  const [selectedItems, setSelectedItems] = useState(new Set<string>())

  const handleParentChange = useCallback(
    (item: ParentItem) => (updatedIds: Set<string>) => {
      const allItemIds = [item.id, ...item.children.map(i => i.id)]
      const deletedIds = allItemIds.filter(id => !updatedIds.has(id))
      deletedIds.forEach(i => selectedItems.delete(i))
      Array.from(updatedIds).forEach(i => selectedItems.add(i))
      setSelectedItems(selectedItems)
      onChange(Array.from(selectedItems))
    },
    [onChange, selectedItems]
  )

  const handleItemChange = useCallback(
    (item: SingleItem) => (selected: boolean) => {
      if (selected) {
        selectedItems.add(item.id)
      } else {
        selectedItems.delete(item.id)
      }
      onChange(Array.from(selectedItems))
    },
    [onChange, selectedItems]
  )

  return (
    <>
      {items.map((item, index) => {
        return (
          <Fragment key={item.id}>
            {item.children ? (
              <ParentItemCheckbox
                parentId={item.id}
                label={item.label}
                items={item.children}
                icon={item.icon}
                onChange={handleParentChange(item)}
              />
            ) : (
              <SingleItemCheckbox
                key={item.id}
                id={item.id}
                label={item.label}
                icon={item.icon}
                onChange={handleItemChange(item)}
              />
            )}
            {index + 1 < items.length && <hr aria-hidden="true" />}
          </Fragment>
        )
      })}
    </>
  )
}

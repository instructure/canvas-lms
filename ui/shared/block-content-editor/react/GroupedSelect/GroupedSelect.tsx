/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {useEffect, useState, useMemo} from 'react'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {List} from '@instructure/ui-list'
import {Responsive} from '@instructure/ui-responsive'
import {useScope as createI18nScope} from '@canvas/i18n'
import {GroupedSelectCompactLayout} from './GroupedSelectCompactLayout'
import {GroupedSelectDesktopLayout} from './GroupedSelectDesktopLayout'
import {GroupedSelectEntry} from './GroupedSelectEntry'
import {useKeyboardNav} from './useKeyboardNav'

const I18n = createI18nScope('block_content_editor')

export type GroupedSelectItem = {
  itemName: string
  id: string
}

export type GroupedSelectData = {
  groupName: string
  items: GroupedSelectItem[]
}

export const GroupedSelect = (props: {
  data: GroupedSelectData[]
  onChange: (item: GroupedSelectItem) => void
}) => {
  const [selectedGroup, setSelectedGroup] = useState(props.data[0].groupName)
  const [selectedItem, setSelectedItem] = useState(props.data[0].items[0])

  const selectedGroupItems = useMemo(
    () => props.data.find(group => group.groupName === selectedGroup)?.items || [],
    [props.data, selectedGroup],
  )

  const handleGroupChange = (group: GroupedSelectData) => {
    setSelectedGroup(group.groupName)
    handleItemChange(group.items[0])
  }

  const handleItemChange = (item: GroupedSelectItem) => {
    setSelectedItem(item)
    props.onChange(item)
  }

  const handleGroupFocus = (groupName: string) => {
    const groupIndex = props.data.findIndex(group => group.groupName === groupName) || 0
    overrideFocus(0, groupIndex)
  }

  const handleItemFocus = (id: string) => {
    const itemIndex = selectedGroupItems.findIndex(item => item.id === id) || 0
    overrideFocus(1, itemIndex)
  }

  const {handleKeyDown, elementsRef, overrideFocus, handleBlur} = useKeyboardNav(
    props.data,
    selectedItem.id,
    selectedGroup,
    selectedGroupItems,
    handleGroupChange,
    handleItemChange,
  )

  useEffect(() => {
    props.onChange(selectedItem)
  }, [])

  return (
    <Responsive
      match="media"
      query={{small: {maxWidth: '767px'}, large: {minWidth: '768px'}}}
      render={(_, matches) => {
        if (matches?.includes('small')) {
          return (
            <GroupedSelectCompactLayout
              group={
                <SimpleSelect
                  width="100%"
                  renderLabel={I18n.t('Block category')}
                  value={selectedGroup}
                  onChange={(_, {value}) => {
                    const group = props.data.find(g => g.groupName === value) || props.data[0]
                    handleGroupChange(group)
                  }}
                >
                  {props.data.map(group => (
                    <SimpleSelect.Option
                      key={group.groupName}
                      id={group.groupName}
                      value={group.groupName}
                    >
                      {group.groupName}
                    </SimpleSelect.Option>
                  ))}
                </SimpleSelect>
              }
              items={
                <SimpleSelect
                  width="100%"
                  renderLabel={I18n.t('Block type')}
                  assistiveText={I18n.t('%{selectedGroup} category items', {
                    selectedGroup: selectedGroup,
                  })}
                  value={selectedItem.id}
                  onChange={(_, {value}) => {
                    const item =
                      selectedGroupItems.find(item => item.id === value) || selectedGroupItems[0]
                    handleItemChange(item)
                  }}
                >
                  {selectedGroupItems.map(item => (
                    <SimpleSelect.Option key={item.id} id={item.id} value={item.id}>
                      {item.itemName}
                    </SimpleSelect.Option>
                  ))}
                </SimpleSelect>
              }
            />
          )
        } else {
          return (
            <GroupedSelectDesktopLayout
              group={
                <List
                  role="group"
                  width="100%"
                  itemSpacing="xx-small"
                  isUnstyled
                  margin="none"
                  data-testid="grouped-select-groups"
                  aria-label={I18n.t('Block category')}
                >
                  {props.data.map(group => (
                    <List.Item key={group.groupName}>
                      <GroupedSelectEntry
                        variant="group"
                        title={group.groupName}
                        active={group.groupName === selectedGroup}
                        ref={(el: HTMLDivElement | null) => {
                          elementsRef.current.set(group.groupName, el)
                        }}
                        onClick={() => {
                          handleGroupChange(group)
                        }}
                        onFocus={() => handleGroupFocus(group.groupName)}
                      />
                    </List.Item>
                  ))}
                </List>
              }
              items={
                <List
                  role="group"
                  width="100%"
                  itemSpacing="xx-small"
                  isUnstyled
                  margin="none"
                  data-testid="grouped-select-items"
                  aria-label={I18n.t('%{selectedGroup} category items', {
                    selectedGroup: selectedGroup,
                  })}
                >
                  {selectedGroupItems.map(item => (
                    <List.Item key={item.id}>
                      <GroupedSelectEntry
                        variant="item"
                        title={item.itemName}
                        active={selectedItem === item}
                        ref={(el: HTMLDivElement | null) => {
                          elementsRef.current.set(item.id, el)
                        }}
                        onClick={() => {
                          handleItemChange(item)
                        }}
                        onFocus={() => handleItemFocus(item.id)}
                      />
                    </List.Item>
                  ))}
                </List>
              }
              onBlur={handleBlur}
              onKeyDown={handleKeyDown}
            />
          )
        }
      }}
    />
  )
}

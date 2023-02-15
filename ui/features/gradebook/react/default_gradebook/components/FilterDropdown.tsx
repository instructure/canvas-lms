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

import React, {MouseEvent, useState, useRef} from 'react'
import {Popover} from '@instructure/ui-popover'
import {Button} from '@instructure/ui-buttons'
import {Menu} from '@instructure/ui-menu'
import {TruncateText} from '@instructure/ui-truncate-text'
import {IconArrowOpenEndLine, IconArrowOpenStartLine, IconFilterLine} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {useScope as useI18nScope} from '@canvas/i18n'
import type {FilterDrilldownData, FilterDrilldownMenuItem} from '../gradebook.d'

const I18n = useI18nScope('gradebook')

const {Group: MenuGroup, Item: MenuItem, Separator: MenuSeparator} = Menu as any

type Props = {
  rootId?: string
  onOpenTray: () => void
  dataMap: FilterDrilldownData
  filterItems: FilterDrilldownData
}

const FilterDropdown = ({
  rootId = 'savedFilterPresets',
  onOpenTray,
  dataMap,
  filterItems,
}: Props) => {
  const [currentItemId, setTempItemId] = useState<string>(rootId)
  const [isOpen, setIsOpen] = useState(false)
  const menuRef = useRef<HTMLElement>()
  const currentObj = dataMap[currentItemId]

  const items = currentObj?.items?.concat() || []

  const selectedIndices = items.reduce<number[]>((acc, current, index) => {
    if (current.isSelected) {
      return acc.concat(index)
    }
    return acc
  }, [])

  const sortedItemGroups = currentObj?.itemGroups || []

  const selectedFilterIndices = Object.values(filterItems).reduce<number[]>(
    (acc, current, index) => {
      if (current.isSelected) {
        return acc.concat(index)
      }
      return acc
    },
    []
  )

  const isRoot = currentItemId === 'savedFilterPresets'

  const setItemId = id => {
    setTempItemId(id)

    if (menuRef.current) {
      menuRef.current.focus()
    }
  }

  const handleTabbingOut = event => {
    // Drilldown should close when Tab is pressed
    if (isOpen && event?.keyCode === 9) {
      // 9 = Tab
      setIsOpen(false)
      setTempItemId(dataMap.savedFilterPresets.id)
    }
  }

  const backButton = (
    <MenuItem
      as="div"
      onClick={() => {
        setItemId(currentObj.parentId)
      }}
    >
      <Flex as="div" justifyItems="start">
        <View margin="0 small 0 0">
          <IconArrowOpenStartLine />
        </View>
        <TruncateText>{I18n.t('Back')}</TruncateText>
      </Flex>
    </MenuItem>
  )

  return (
    <View as="div">
      <Popover
        renderTrigger={<Button renderIcon={IconFilterLine}>{I18n.t('Apply Filters')}</Button>}
        shouldRenderOffscreen={false}
        on="click"
        placement="bottom start"
        constrain="window"
        offsetY={8}
        isOpen={isOpen}
        onShowContent={() => {
          setIsOpen(true)
        }}
        onHideContent={() => {
          setTempItemId(dataMap.savedFilterPresets.id)
          setIsOpen(false)
        }}
      >
        {isRoot && (
          <Menu
            menuRef={ref => {
              menuRef.current = ref
            }}
            onKeyDown={handleTabbingOut}
          >
            {items.length > 0 && (
              <MenuGroup
                label={I18n.t('Saved Filter Presets')}
                onSelect={(_event: MouseEvent, updated: [number, ...number[]]) => {
                  items[updated[0]].onToggle?.()
                }}
                selected={selectedIndices}
              >
                {items.map(a => {
                  return (
                    <MenuItem key={a.id} as="div">
                      <TruncateText>{a.name}</TruncateText>
                    </MenuItem>
                  )
                })}
              </MenuGroup>
            )}

            <MenuItem
              as="div"
              test-id="manage-filter-presets-button"
              onSelect={() => {
                setIsOpen(false)
                onOpenTray()
              }}
            >
              <TruncateText>{I18n.t('Create & Manage Filter Presets')}</TruncateText>
            </MenuItem>

            <MenuSeparator />

            <MenuGroup label={I18n.t('Filters')} selected={selectedFilterIndices}>
              {Object.values(filterItems).map((item: FilterDrilldownMenuItem) => {
                return (
                  <MenuItem
                    key={item.id}
                    as="div"
                    onSelect={() => {
                      if (item.onToggle) {
                        item.onToggle()
                      } else {
                        setItemId(item.id)
                      }
                    }}
                    selected={item.isSelected}
                  >
                    <Flex as="div" justifyItems="space-between">
                      <TruncateText>{item.name}</TruncateText>
                      {((item.items?.length || 0) > 0 || (item.itemGroups?.length || 0) > 0) && (
                        <View margin="0 0 0 small">
                          <IconArrowOpenEndLine />
                        </View>
                      )}
                    </Flex>
                  </MenuItem>
                )
              })}
            </MenuGroup>
          </Menu>
        )}

        {!isRoot && (
          <Menu
            menuRef={ref => {
              menuRef.current = ref
            }}
            onKeyDown={handleTabbingOut}
          >
            {backButton}

            {sortedItemGroups.length > 0 && (
              <MenuGroup label={currentObj.name}>
                <MenuSeparator />
              </MenuGroup>
            )}

            {sortedItemGroups.length > 0 &&
              sortedItemGroups.map((itemGroup: any) => {
                const selectedIndices2 = itemGroup.items.reduce((acc, current, index) => {
                  if (current.isSelected) {
                    return acc.concat(index)
                  }
                  return acc
                }, [])

                return (
                  <MenuGroup
                    key={itemGroup.id}
                    label={itemGroup.name}
                    selected={selectedIndices2}
                    onSelect={(_event, updated) => {
                      itemGroup.items[updated[0]].onToggle()
                    }}
                  >
                    {itemGroup.items.map((item: any) => {
                      return (
                        <MenuItem key={item.id} as="div">
                          <Flex as="div" justifyItems="space-between">
                            <TruncateText>{item.name}</TruncateText>
                          </Flex>
                        </MenuItem>
                      )
                    })}
                  </MenuGroup>
                )
              })}

            {items.length > 0 && (
              <MenuGroup
                label={currentObj.name}
                selected={selectedIndices}
                onSelect={(_event: MouseEvent, updated: [number, ...number[]]) =>
                  items[updated[0]].onToggle?.()
                }
              >
                <MenuSeparator />
                {items.map(a => {
                  return (
                    <MenuItem key={a.id} as="div">
                      <TruncateText position="middle">{a.name}</TruncateText>
                    </MenuItem>
                  )
                })}
              </MenuGroup>
            )}
          </Menu>
        )}
      </Popover>
    </View>
  )
}

export default FilterDropdown

// @ts-nocheck
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

import React, {MouseEvent, useState, useRef, useEffect} from 'react'
import {AccessibleContent} from '@instructure/ui-a11y-content'
import {Popover} from '@instructure/ui-popover'
import {Button} from '@instructure/ui-buttons'
import {Menu} from '@instructure/ui-menu'
import {TruncateText} from '@instructure/ui-truncate-text'
import {IconArrowOpenEndLine, IconArrowOpenStartLine, IconFilterLine} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Tooltip} from '@instructure/ui-tooltip'
import {useScope as useI18nScope} from '@canvas/i18n'
import {unescape} from '@instructure/html-escape'
import type {FilterDrilldownData, FilterDrilldownMenuItem} from '../gradebook.d'

const I18n = useI18nScope('gradebook')

type Props = {
  rootId?: string
  onOpenTray: () => void
  dataMap: FilterDrilldownData
  filterItems: FilterDrilldownData
  changeAnnouncement: (filterAnnouncement) => void
  applyFiltersButtonRef: React.RefObject<HTMLButtonElement>
  multiselectGradebookFiltersEnabled?: boolean
}

const TruncateWithTooltip = ({children}: {children: React.ReactNode}) => {
  const [isTruncated, setIsTruncated] = useState(false)
  return isTruncated ? (
    <Tooltip as="div" placement="end" renderTip={children}>
      <TruncateText position="middle" onUpdate={setIsTruncated}>
        {children}
      </TruncateText>
    </Tooltip>
  ) : (
    <TruncateText onUpdate={setIsTruncated} position="middle">
      {children}
    </TruncateText>
  )
}

const FilterDropdown = ({
  rootId = 'savedFilterPresets',
  onOpenTray,
  dataMap,
  filterItems,
  changeAnnouncement,
  applyFiltersButtonRef,
  multiselectGradebookFiltersEnabled = false,
}: Props) => {
  const [currentItemId, setTempItemId] = useState<string>(rootId)
  const [isOpen, setIsOpen] = useState(false)
  const menuRef = useRef<HTMLElement | null>(null)
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

  useEffect(() => {
    if (menuRef.current) {
      menuRef.current.focus()
    }
  }, [isRoot])

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
    <Menu.Item
      as="div"
      data-testid="back-button"
      onClick={() => {
        setItemId(currentObj.parentId)
      }}
    >
      <Flex as="div" justifyItems="start">
        <View margin="0 small 0 0">
          <IconArrowOpenStartLine />
        </View>
        {I18n.t('Back')}
      </Flex>
    </Menu.Item>
  )

  return (
    <View as="div">
      <Popover
        renderTrigger={
          <Button
            elementRef={ref => (applyFiltersButtonRef.current = ref)}
            data-testid="apply-filters-button"
            renderIcon={IconFilterLine}
          >
            {I18n.t('Apply Filters')}
          </Button>
        }
        shouldRenderOffscreen={false}
        on="click"
        placement="bottom start"
        constrain="window"
        offsetY={8}
        isShowingContent={isOpen}
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
              <Menu.Group
                label={I18n.t('Saved Filter Presets')}
                onSelect={(_event: MouseEvent, updated: [number, ...number[]]) => {
                  items[updated[0]].onToggle?.()
                }}
                selected={selectedIndices}
              >
                {items.map(a => {
                  return (
                    <Menu.Item key={a.id} as="div" data-testid={`${a.name}-enable-preset`}>
                      <TruncateWithTooltip position="middle">{a.name}</TruncateWithTooltip>
                    </Menu.Item>
                  )
                })}
              </Menu.Group>
            )}

            <Menu.Item
              as="div"
              data-testid="manage-filter-presets-button"
              onSelect={() => {
                setIsOpen(false)
                onOpenTray()
              }}
            >
              <TruncateText>{I18n.t('Create & Manage Filter Presets')}</TruncateText>
            </Menu.Item>

            <Menu.Separator />

            <Menu.Group
              label={I18n.t('Filters')}
              selected={selectedFilterIndices}
              onSelect={() => {
                // noop
              }}
            >
              {Object.values(filterItems).map((item: FilterDrilldownMenuItem) => {
                return (
                  <Menu.Item
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
                    data-testid={`${item.name}-filter-type`}
                  >
                    <Flex as="div" justifyItems="space-between">
                      <TruncateText position="middle">{item.name}</TruncateText>
                      {((item.items?.length || 0) > 0 || (item.itemGroups?.length || 0) > 0) && (
                        <View margin="0 0 0 small">
                          <IconArrowOpenEndLine />
                        </View>
                      )}
                    </Flex>
                  </Menu.Item>
                )
              })}
            </Menu.Group>
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
              <Menu.Group label={currentObj.name}>
                <Menu.Separator />
              </Menu.Group>
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
                  <Menu.Group
                    allowMultiple={multiselectGradebookFiltersEnabled}
                    key={itemGroup.id}
                    label={itemGroup.name}
                    selected={selectedIndices2}
                    onSelect={(_event, updated) => {
                      if (multiselectGradebookFiltersEnabled) {
                        return
                      }

                      itemGroup.items[updated[0]].onToggle()
                    }}
                  >
                    {itemGroup.items.map((item: any) => {
                      // TODO: remove this when we stop recursively mutating and escaping objects in Gradebook.tsx
                      // (-_-)
                      const unescapedName = unescape(item.name)
                      return (
                        <Menu.Item
                          data-testid={`${item.name}-sorted-filter`}
                          key={item.id}
                          as="div"
                          onSelect={() => {
                            if (!multiselectGradebookFiltersEnabled) {
                              return
                            }

                            item.onToggle()
                          }}
                        >
                          <Flex as="div" justifyItems="space-between">
                            <TruncateText position="middle">{unescapedName}</TruncateText>
                          </Flex>
                        </Menu.Item>
                      )
                    })}
                  </Menu.Group>
                )
              })}

            {items.length > 0 && (
              <Menu.Group
                allowMultiple={multiselectGradebookFiltersEnabled}
                label={currentObj.name}
                selected={selectedIndices}
                onSelect={(_event: MouseEvent, updated: [number, ...number[]]) => {
                  if (multiselectGradebookFiltersEnabled) {
                    return
                  }

                  if (items[updated[0]].isSelected) {
                    changeAnnouncement(
                      I18n.t('Removed %{filterName} Filter', {filterName: items[updated[0]].name})
                    )
                  } else {
                    changeAnnouncement(
                      I18n.t('Added %{filterName} Filter', {filterName: items[updated[0]].name})
                    )
                  }
                  items[updated[0]].onToggle?.()
                }}
              >
                <Menu.Separator />
                {items.map(item => {
                  return (
                    <Menu.Item
                      data-testid={`${item.name}-filter`}
                      key={item.id}
                      as="div"
                      onSelect={() => {
                        if (!multiselectGradebookFiltersEnabled) {
                          return
                        }

                        if (item.isSelected) {
                          changeAnnouncement(
                            I18n.t('Removed %{filterName} Filter', {filterName: item.name})
                          )
                        } else {
                          changeAnnouncement(
                            I18n.t('Added %{filterName} Filter', {filterName: item.name})
                          )
                        }

                        item.onToggle?.()
                      }}
                    >
                      <AccessibleContent alt={item.name}>
                        <TruncateWithTooltip>{item.name}</TruncateWithTooltip>
                      </AccessibleContent>
                    </Menu.Item>
                  )
                })}
              </Menu.Group>
            )}
          </Menu>
        )}
      </Popover>
    </View>
  )
}

export default FilterDropdown

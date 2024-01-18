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
import React from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Popover} from '@instructure/ui-popover'
import {Menu} from '@instructure/ui-menu'
import type {FilterDrilldownMenuItem, FilterType} from '../gradebook.d'
import {Flex} from '@instructure/ui-flex'
import {IconXLine} from '@instructure/ui-icons'
import {TruncateText} from '@instructure/ui-truncate-text'
import {View} from '@instructure/ui-view'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

const I18n = useI18nScope('gradebook')

type FilterNavPopoverProps = {
  filterType?: FilterType
  isOpen: boolean
  menuGroups: FilterDrilldownMenuItem[]
  menuItems: FilterDrilldownMenuItem[]
  renderTrigger: React.ReactNode
  handleHideFilter: () => void
  handleRemoveFilter: () => void
  handleSelectFilter: () => void
}

export const FilterNavPopover = ({
  filterType,
  isOpen,
  menuGroups,
  menuItems,
  renderTrigger,
  handleHideFilter,
  handleRemoveFilter,
  handleSelectFilter,
}: FilterNavPopoverProps) => {
  const selectedFilterIndices = Object.values(menuItems).reduce<number[]>((acc, current, index) => {
    if (current.isSelected) {
      return acc.concat(index)
    }
    return acc
  }, [])

  return (
    <Popover
      renderTrigger={renderTrigger}
      isShowingContent={isOpen}
      on="click"
      screenReaderLabel={I18n.t('Filter Options')}
      shouldCloseOnDocumentClick={true}
      shouldRenderOffscreen={false}
      onShowContent={() => {}}
      onHideContent={handleHideFilter}
      offsetY="10px"
    >
      <Menu>
        <Menu.Item onClick={handleRemoveFilter} data-testid="remove-filter-popover-menu-item">
          <IconXLine size="x-small" />{' '}
          <View as="span" margin="0 0 0 xxx-small">
            {I18n.t('Remove Filter')}
          </View>
        </Menu.Item>
        <Menu.Separator />

        {filterType === 'start-date' || filterType === 'end-date' ? (
          <Menu.Group
            label={
              <ScreenReaderContent>
                {I18n.t('Start and End Date Filter Selections')}
              </ScreenReaderContent>
            }
            selected={selectedFilterIndices}
            onSelect={() => {}}
          >
            <Menu.Item
              key="startAndEndDate"
              as="div"
              onSelect={() => {
                handleHideFilter()
                handleSelectFilter()
              }}
              data-testid={`${filterType}-filter-type`}
            >
              {I18n.t('Edit Date')}
            </Menu.Item>
          </Menu.Group>
        ) : menuGroups.length ? (
          menuGroups.map(itemGroup => {
            const selectedIndices2 = itemGroup.items?.reduce((acc, current, index) => {
              if (current.isSelected) {
                return acc.concat(index)
              }
              return acc
            }, [] as number[])

            return (
              <Menu.Group
                key={itemGroup.id}
                data-testid={`${itemGroup.name}-sorted-filter-group`}
                label={itemGroup.name}
                selected={selectedIndices2}
                onSelect={(_event, updated) => {
                  itemGroup.items?.[updated[0] as number]?.onToggle?.()
                }}
              >
                {itemGroup.items?.map((item: any) => {
                  const unescapedName = unescape(item.name)
                  return (
                    <Menu.Item
                      data-testid={`${item.name}-sorted-filter-group-item`}
                      key={item.id}
                      as="div"
                    >
                      <Flex as="div" justifyItems="space-between">
                        <TruncateText position="middle">{unescapedName}</TruncateText>
                      </Flex>
                    </Menu.Item>
                  )
                })}
              </Menu.Group>
            )
          })
        ) : (
          <Menu.Group
            label={<ScreenReaderContent>{I18n.t('Filter Selections')}</ScreenReaderContent>}
            selected={selectedFilterIndices}
            onSelect={() => {}}
          >
            {menuItems.map(item => {
              return (
                <Menu.Item
                  key={item.id}
                  as="div"
                  onSelect={() => {
                    item.onToggle?.()
                    handleSelectFilter()
                  }}
                  selected={item.isSelected}
                  data-testid={`${item.name}-filter-type`}
                >
                  <Flex as="div" justifyItems="space-between">
                    <TruncateText position="middle">{item.name}</TruncateText>
                  </Flex>
                </Menu.Item>
              )
            })}
          </Menu.Group>
        )}
      </Menu>
    </Popover>
  )
}

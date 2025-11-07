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
import React from 'react'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {IconButton} from '@instructure/ui-buttons'
import {useScope as createI18nScope} from '@canvas/i18n'
import {IconArrowOpenDownLine, IconArrowDownLine, IconArrowUpLine} from '@instructure/ui-icons'
import {Menu} from '@instructure/ui-menu'
import {View} from '@instructure/ui-view'
import {
  CELL_HEIGHT,
  SortOrder,
  SortBy,
  STUDENT_COLUMN_WIDTH,
  NameDisplayFormat,
} from '../../utils/constants'
import {Sorting} from '../../types/shapes'

const I18n = createI18nScope('learning_mastery_gradebook')

const getSortByForFormat = (format: NameDisplayFormat): SortBy => {
  return format === NameDisplayFormat.LAST_FIRST ? SortBy.SortableName : SortBy.Name
}

export interface StudentHeaderProps {
  sorting: Sorting
  nameDisplayFormat: NameDisplayFormat
  onChangeNameDisplayFormat: (format: NameDisplayFormat) => void
}

export const StudentHeader: React.FC<StudentHeaderProps> = ({
  sorting,
  nameDisplayFormat,
  onChangeNameDisplayFormat,
}) => {
  const handleNameDisplayFormatChange = React.useCallback(
    (format: NameDisplayFormat) => {
      onChangeNameDisplayFormat(format)
      // When display format changes and we're currently sorting by name or sortable name,
      // update the sort to match the new format
      if (sorting.sortBy === SortBy.Name || sorting.sortBy === SortBy.SortableName) {
        const newSortBy = getSortByForFormat(format)
        sorting.setSortBy(newSortBy)
      }
    },
    [onChangeNameDisplayFormat, sorting],
  )

  const handleNameSortClick = React.useCallback(() => {
    // When sorting by name, use sortable name for "Last, First" format
    // and regular name for "First, Last" format
    const sortBy = getSortByForFormat(nameDisplayFormat)
    sorting.setSortBy(sortBy)
  }, [nameDisplayFormat, sorting])

  return (
    <View background="secondary" as="div" width={STUDENT_COLUMN_WIDTH}>
      <Flex alignItems="center" justifyItems="space-between" height={CELL_HEIGHT}>
        <Flex.Item padding="0 0 0 small">
          <Text weight="bold">{I18n.t('Students')}</Text>
        </Flex.Item>
        <Flex.Item padding="0 small 0 0">
          <Menu
            placement="bottom"
            trigger={
              <IconButton
                withBorder={false}
                withBackground={false}
                size="small"
                screenReaderLabel={I18n.t('Student Options')}
              >
                <IconArrowOpenDownLine />
              </IconButton>
            }
          >
            <Menu.Group label={I18n.t('Display as')}>
              <Menu.Item
                onSelect={() => handleNameDisplayFormatChange(NameDisplayFormat.FIRST_LAST)}
                selected={nameDisplayFormat === NameDisplayFormat.FIRST_LAST}
              >
                {I18n.t('First, Last Name')}
              </Menu.Item>
              <Menu.Item
                onSelect={() => handleNameDisplayFormatChange(NameDisplayFormat.LAST_FIRST)}
                selected={nameDisplayFormat === NameDisplayFormat.LAST_FIRST}
              >
                {I18n.t('Last, First Name')}
              </Menu.Item>
            </Menu.Group>
            <Menu.Group label={I18n.t('Sort Order')}></Menu.Group>
            <Menu.Item onClick={() => sorting.setSortOrder(SortOrder.ASC)}>
              <Flex gap="x-small">
                <IconArrowUpLine spacing="small" />
                <Text weight={sorting.sortOrder === SortOrder.ASC ? 'bold' : 'normal'}>
                  {I18n.t('Ascending')}
                </Text>
              </Flex>
            </Menu.Item>
            <Menu.Item onClick={() => sorting.setSortOrder(SortOrder.DESC)}>
              <Flex gap="x-small">
                <IconArrowDownLine spacing="small" />
                <Text weight={sorting.sortOrder === SortOrder.DESC ? 'bold' : 'normal'}>
                  {I18n.t('Descending')}
                </Text>
              </Flex>
            </Menu.Item>
            <Menu.Group label={I18n.t('Sort By')}>
              <Menu.Item
                onSelect={handleNameSortClick}
                selected={sorting.sortBy === SortBy.Name || sorting.sortBy === SortBy.SortableName}
              >
                {I18n.t('Name')}
              </Menu.Item>
              <Menu.Item
                onSelect={() => sorting.setSortBy(SortBy.SisId)}
                selected={sorting.sortBy === SortBy.SisId}
              >
                {I18n.t('SIS ID')}
              </Menu.Item>
              <Menu.Item
                onSelect={() => sorting.setSortBy(SortBy.IntegrationId)}
                selected={sorting.sortBy === SortBy.IntegrationId}
              >
                {I18n.t('Integration ID')}
              </Menu.Item>
              <Menu.Item
                onSelect={() => sorting.setSortBy(SortBy.LoginId)}
                selected={sorting.sortBy === SortBy.LoginId}
              >
                {I18n.t('Login ID')}
              </Menu.Item>
            </Menu.Group>
          </Menu>
        </Flex.Item>
      </Flex>
    </View>
  )
}

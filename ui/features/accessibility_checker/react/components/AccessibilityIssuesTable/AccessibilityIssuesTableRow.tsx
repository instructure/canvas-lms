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

import {useCallback} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {IconPublishSolid, IconUnpublishedSolid} from '@instructure/ui-icons'
import {Link} from '@instructure/ui-link'
import {Table, TableCellProps} from '@instructure/ui-table'
import {Text} from '@instructure/ui-text'

import {ContentItem} from '../../types'
import {ContentTypeCell} from './ContentTypeCell'
import {IssueCell} from './IssueCell'

const I18n = createI18nScope('accessibility_checker')

const baseCellThemeOverride: TableCellProps['themeOverride'] = (_componentTheme, currentTheme) => ({
  padding: '1.0625rem 0.75rem', // Make cell height a total of 3.75rem at minimum
})

type Props = {
  item: ContentItem
  // Could be renamed to onIssueRemediationClick for clarity
  onRowClick?: (item: ContentItem) => void
}

export const AccessibilityIssuesTableRow = ({item, onRowClick}: Props) => {
  const handleRowClick = useCallback(
    (item: ContentItem) => {
      if (onRowClick) {
        onRowClick(item)
      }
    },
    [onRowClick],
  )

  return (
    <Table.Row key={`${item.type}-${item.id}`} data-testid={`issue-row-${item.id}`}>
      <Table.Cell themeOverride={baseCellThemeOverride} textAlign="start">
        <Link href={item.url}>
          <Text lineHeight="lineHeight150">{item.title}</Text>
        </Link>
      </Table.Cell>
      <Table.Cell textAlign="center">
        <IssueCell item={item} onClick={handleRowClick} />
      </Table.Cell>
      <Table.Cell>
        <ContentTypeCell item={item} />
      </Table.Cell>
      <Table.Cell>
        <Flex alignItems="center">
          {item.published ? (
            <>
              <Flex.Item margin="0 x-small 0 0">
                <IconPublishSolid color="success" />
              </Flex.Item>
              <Flex.Item>
                <Text>{I18n.t('Published')}</Text>
              </Flex.Item>
            </>
          ) : (
            <>
              <Flex.Item margin="0 x-small 0 0">
                <IconUnpublishedSolid color="secondary" />
              </Flex.Item>
              <Flex.Item>
                <Text>{I18n.t('Unpublished')}</Text>
              </Flex.Item>
            </>
          )}
        </Flex>
      </Table.Cell>
      <Table.Cell themeOverride={baseCellThemeOverride}>
        <Text lineHeight="lineHeight150">
          {item.updatedAt
            ? new Intl.DateTimeFormat('en-US', {
                year: 'numeric',
                month: 'short',
                day: '2-digit',
              }).format(new Date(item.updatedAt))
            : '-'}
        </Text>
      </Table.Cell>
    </Table.Row>
  )
}

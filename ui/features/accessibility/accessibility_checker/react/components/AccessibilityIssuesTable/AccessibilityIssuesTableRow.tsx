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

import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {IconPublishSolid, IconUnpublishedSolid} from '@instructure/ui-icons'
import {Link} from '@instructure/ui-link'
import {Table, TableCellProps} from '@instructure/ui-table'
import {Text} from '@instructure/ui-text'

import {AccessibilityResourceScan, ResourceWorkflowState} from '../../../../shared/react/types'
import {ContentTypeCell} from './Cells/ContentTypeCell'
import {ScanStateCell} from './Cells/ScanStateCell'

const I18n = createI18nScope('accessibility_checker')

const baseCellThemeOverride: TableCellProps['themeOverride'] = _componentTheme => ({
  padding: '1.0625rem 0.75rem', // Make cell height a total of 3.75rem at minimum
})

type Props = {
  item: AccessibilityResourceScan
  isMobile: boolean
}

export const AccessibilityIssuesTableRow = ({item, isMobile}: Props) => (
  <Table.Row key={`${item.resourceType}-${item.id}`} data-testid={`issue-row-${item.id}`}>
    <Table.Cell themeOverride={baseCellThemeOverride} textAlign="start">
      <Link href={item.resourceUrl}>
        <Text lineHeight="lineHeight150">{item.resourceName}</Text>
      </Link>
    </Table.Cell>
    <Table.Cell>
      <ScanStateCell item={item} isMobile={isMobile} />
    </Table.Cell>
    <Table.Cell>
      <ContentTypeCell item={item} />
    </Table.Cell>
    <Table.Cell>
      <Flex alignItems="center" gap="x-small">
        {item.resourceWorkflowState === ResourceWorkflowState.Published ? (
          <>
            <Flex.Item>
              <Flex>
                <IconPublishSolid color="success" aria-hidden="true" />
              </Flex>
            </Flex.Item>
            <Flex.Item>
              <Text>{I18n.t('Published')}</Text>
            </Flex.Item>
          </>
        ) : (
          <>
            <Flex.Item>
              <Flex>
                <IconUnpublishedSolid color="secondary" aria-hidden="true" />
              </Flex>
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
        {item.resourceUpdatedAt
          ? new Intl.DateTimeFormat('en-US', {
              year: 'numeric',
              month: 'short',
              day: '2-digit',
            }).format(new Date(item.resourceUpdatedAt))
          : '-'}
      </Text>
    </Table.Cell>
  </Table.Row>
)

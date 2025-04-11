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
import {canvas} from '@instructure/ui-themes'
import {Table} from '@instructure/ui-table'
import {Heading} from '@instructure/ui-heading'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Responsive} from '@instructure/ui-responsive'
import type {ContentMigrationItem, UpdateMigrationItemType} from './types'
import MigrationRow from './migration_row'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'
import InfiniteScroll from '@canvas/infinite-scroll/react/components/InfiniteScroll'

const I18n = createI18nScope('content_migrations_redesign')

const LoadingSpinner = () => (
  <Table.Row>
    <Table.Cell colSpan={headerData.length} textAlign="center">
      <View as="div" margin="medium none" textAlign="center">
        <Spinner size="small" renderTitle={I18n.t('Loading')} />
      </View>
    </Table.Cell>
  </Table.Row>
)

type HeaderData = {
  id: string
  label: React.ReactNode
  textAlign?: 'start' | 'center' | 'end'
}

const headerData: HeaderData[] = [
  {id: 'content_type', label: <strong>{I18n.t('Content Type')}</strong>},
  {id: 'source_link', label: <strong>{I18n.t('Source Link')}</strong>},
  {id: 'date_imported', label: <strong>{I18n.t('Date Imported')}</strong>},
  {id: 'status', label: <strong>{I18n.t('Status')}</strong>, textAlign: 'center'},
  {id: 'progress', label: <strong>{I18n.t('Progress')}</strong>, textAlign: 'center'},
  {id: 'action', label: <strong>{I18n.t('Action')}</strong>, textAlign: 'center'},
]

export type ContentMigrationsTableProps = {
  migrations: ContentMigrationItem[]
  isLoading: boolean
  hasMore?: boolean
  fetchNext: () => void
  updateMigrationItem: UpdateMigrationItemType
}

export const ContentMigrationsTable = ({
  migrations,
  isLoading,
  hasMore = false,
  fetchNext,
  updateMigrationItem,
}: ContentMigrationsTableProps) => {
  const loadMore = () => {
    if (isLoading || !hasMore) return
    fetchNext()
  }

  const migrationsExpireDays = ENV.CONTENT_MIGRATIONS_EXPIRE_DAYS

  return (
    <View as="div" borderWidth="small 0 0 0" padding="small 0 0 0">
      <Heading level="h3" as="h3" margin="small 0">
        {I18n.t('Content imports')}
      </Heading>
      {!!migrationsExpireDays && (
        <View as="div" margin="small 0 medium 0">
          {I18n.t('Content import files cannot be downloaded after %{days} days.', {
            days: migrationsExpireDays,
          })}
        </View>
      )}
      <Responsive
        match="media"
        query={{
          expanded: {minWidth: canvas.breakpoints.medium},
        }}
        render={(_, matches) => {
          const layout = matches?.includes('expanded') ? 'auto' : 'stacked'
          return (
            <InfiniteScroll pageStart={1} loadMore={loadMore} hasMore={!isLoading && hasMore}>
              <Table caption={I18n.t('Content Migrations')} layout={layout}>
                <Table.Head>
                  <Table.Row>
                    {headerData.map(header => (
                      <Table.ColHeader
                        key={header.id}
                        id={header.id}
                        themeOverride={{padding: '0.6rem 0'}}
                        textAlign={header.textAlign || 'start'}
                      >
                        {header.label}
                      </Table.ColHeader>
                    ))}
                  </Table.Row>
                </Table.Head>
                <Table.Body>
                  {migrations.map((cm: ContentMigrationItem) => (
                    <MigrationRow
                      key={cm.id}
                      migration={cm}
                      layout={layout}
                      updateMigrationItem={updateMigrationItem}
                    />
                  ))}
                  {isLoading && <LoadingSpinner />}
                </Table.Body>
              </Table>
            </InfiniteScroll>
          )
        }}
      />
    </View>
  )
}

export default ContentMigrationsTable

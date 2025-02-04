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
import {canvas} from '@instructure/ui-theme-tokens'
import {Flex} from '@instructure/ui-flex'
import {Table} from '@instructure/ui-table'
import {Heading} from '@instructure/ui-heading'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Responsive} from '@instructure/ui-responsive'
import type {ContentMigrationItem, UpdateMigrationItemType} from './types'
import MigrationRow from './migration_row'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'

const I18n = createI18nScope('content_migrations_redesign')

const LoadingSpinner = () => (
  <View as="div" margin="medium none" textAlign="center">
    <Spinner size="small" renderTitle={I18n.t('Loading')} />
  </View>
)


type ContentMigrationsTableViewProps = {
  migrations: ContentMigrationItem[]
  isLoading: boolean
  updateMigrationItem: (
    migrationId: string,
    data: any,
    noXHR: boolean | undefined,
  ) => Promise<ContentMigrationItem | undefined>
}

const ContentMigrationsTableCondensedView = ({
  migrations,
  isLoading,
  updateMigrationItem,
}: ContentMigrationsTableViewProps) => {
  return (
    <Flex justifyItems="center" direction="column" gap="small">
      {migrations.map((cm: ContentMigrationItem) => (
        <MigrationRow
          key={cm.id}
          migration={cm}
          view="condensed"
          updateMigrationItem={updateMigrationItem}
        />
      ))}
      {isLoading && (<LoadingSpinner />)}
    </Flex>
  )
}

const ContentMigrationsTableExpandedView = ({
  migrations,
  isLoading,
  updateMigrationItem,
}: ContentMigrationsTableViewProps) => {
  return (
    <Table caption={I18n.t('Content Migrations')}>
      {renderTableHeader()}
      <Table.Body>
        {migrations.map((cm: ContentMigrationItem) => (
          <MigrationRow
            key={cm.id}
            migration={cm}
            view="expanded"
            updateMigrationItem={updateMigrationItem}
          />
        ))}
        {isLoading && 
          <Table.Row>
            <Table.Cell colSpan={6} textAlign="center">
              <LoadingSpinner />
            </Table.Cell>
          </Table.Row>
        }
      </Table.Body>
    </Table>
  )
}

export type ContentMigrationsTableProps = {
  migrations: ContentMigrationItem[]
  isLoading: boolean
  updateMigrationItem: UpdateMigrationItemType
}

export const ContentMigrationsTable = ({
  migrations,
  isLoading,
  updateMigrationItem,
}: ContentMigrationsTableProps) => {

  return (
    <>
      <Heading level="h2" as="h2" margin="small 0">
        {I18n.t('Import Activity')}
      </Heading>
      <hr role="presentation" aria-hidden="true" />
      <Responsive
        match="media"
        query={{
          expanded: {minWidth: canvas.breakpoints.medium},
        }}
        render={(_, matches) => {
          if (matches?.includes('expanded')) {
            return (
              <ContentMigrationsTableExpandedView
                migrations={migrations}
                isLoading={isLoading}
                updateMigrationItem={updateMigrationItem}
              />
            )
          } else {
            return (
              <ContentMigrationsTableCondensedView
                migrations={migrations}
                isLoading={isLoading}
                updateMigrationItem={updateMigrationItem}
              />
            )
          }
        }}
      />
    </>
  )
}

const renderTableHeader = () => {
  return (
    <Table.Head>
      <Table.Row>
        <Table.ColHeader themeOverride={{padding: '0.6rem 0'}} id="content_type">
          {I18n.t('Content Type')}
        </Table.ColHeader>
        <Table.ColHeader themeOverride={{padding: '0.6rem 0'}} id="source_link">
          {I18n.t('Source Link')}
        </Table.ColHeader>
        <Table.ColHeader themeOverride={{padding: '0.6rem 0'}} id="date_imported">
          {I18n.t('Date Imported')}
        </Table.ColHeader>
        <Table.ColHeader themeOverride={{padding: '0.6rem 0'}} textAlign="center" id="status">
          {I18n.t('Status')}
        </Table.ColHeader>
        <Table.ColHeader themeOverride={{padding: '0.6rem 0'}} textAlign="center" id="progress">
          {I18n.t('Progress')}
        </Table.ColHeader>
        <Table.ColHeader themeOverride={{padding: '0.6rem 0'}} textAlign="center" id="action">
          {I18n.t('Action')}
        </Table.ColHeader>
      </Table.Row>
    </Table.Head>
  )
}

export default ContentMigrationsTable

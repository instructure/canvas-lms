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

import React, {useEffect, useCallback} from 'react'
import type {SetStateAction, Dispatch} from 'react'
import {canvas} from '@instructure/ui-theme-tokens'
import {Flex} from '@instructure/ui-flex'
import {Table} from '@instructure/ui-table'
import {Heading} from '@instructure/ui-heading'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {useScope as createI18nScope} from '@canvas/i18n'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {Responsive} from '@instructure/ui-responsive'
import type {ContentMigrationItem, UpdateMigrationItemType} from './types'
import MigrationRow from './migration_row'

const I18n = createI18nScope('content_migrations_redesign')

type MigrationsResponse = {json: ContentMigrationItem[]}

type ContentMigrationsTableViewProps = {
  migrations: ContentMigrationItem[]
  updateMigrationItem: (
    migrationId: string,
    data: any,
    noXHR: boolean | undefined
  ) => Promise<ContentMigrationItem | undefined>
}

const ContentMigrationsTableCondensedView = ({
  migrations,
  updateMigrationItem,
}: ContentMigrationsTableViewProps) => {
  return (
    <Flex direction="column" gap="small">
      {migrations.map((cm: ContentMigrationItem) => (
        <MigrationRow
          key={cm.id}
          migration={cm}
          view="condensed"
          updateMigrationItem={updateMigrationItem}
        />
      ))}
    </Flex>
  )
}

const ContentMigrationsTableExpandedView = ({
  migrations,
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
      </Table.Body>
    </Table>
  )
}

export const ContentMigrationsTable = ({
  migrations,
  setMigrations,
}: {
  migrations: ContentMigrationItem[]
  setMigrations: Dispatch<SetStateAction<ContentMigrationItem[]>>
}) => {
  useEffect(() => {
    doFetchApi({
      path: `/api/v1/courses/${window.ENV.COURSE_ID}/content_migrations`,
      params: {per_page: 25},
    })
      // @ts-expect-error
      .then((response: MigrationsResponse) => setMigrations(_prevMigrations => response.json))
      .catch(showFlashError(I18n.t("Couldn't load previous content migrations")))
  }, [setMigrations])

  const updateMigrationItem: UpdateMigrationItemType = useCallback(
    async (migrationId: string, data: any, noXHR: boolean | undefined) => {
      if (noXHR) {
        setMigrations(prevMigrations =>
          prevMigrations.map((m: ContentMigrationItem) =>
            m.id === migrationId ? {...m, ...data} : m
          )
        )
      } else {
        try {
          const response = await doFetchApi<ContentMigrationItem>({
            path: `/api/v1/courses/${window.ENV.COURSE_ID}/content_migrations/${migrationId}`,
          })
          const json = response.json
          setMigrations(prevMigrations =>
            prevMigrations.map((m: ContentMigrationItem) =>
              m.id === migrationId ? {...json, ...data} : m
            )
          )
          return json
        } catch {
          showFlashError(I18n.t("Couldn't update content migrations"))
        }
      }
    },
    [setMigrations]
  )

  return (
    <>
      <Heading level="h2" as="h2" margin="small 0">
        {I18n.t('Import Queue')}
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
                updateMigrationItem={updateMigrationItem}
              />
            )
          } else {
            return (
              <ContentMigrationsTableCondensedView
                migrations={migrations}
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

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
// @ts-ignore
import {canvas} from '@instructure/ui-theme-tokens'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Grid} from '@instructure/ui-grid'
import {Text} from '@instructure/ui-text'
import {Table} from '@instructure/ui-table'
import {Heading} from '@instructure/ui-heading'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {useScope as useI18nScope} from '@canvas/i18n'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {datetimeString} from '@canvas/datetime/date-functions'
import {Responsive} from '@instructure/ui-responsive'
import {StatusPill} from './status_pill'
import {SourceLink} from './source_link'
import {ContentMigrationItem} from './types'
import {ActionButton} from './action_button'
import {buildProgressCellContent} from './completion_progress_bar'

const I18n = useI18nScope('content_migrations_redesign')

type MigrationsResponse = {json: ContentMigrationItem[]}
type MigrationResponse = {json: ContentMigrationItem}

type ContentMigrationsTableViewProps = {
  migrations: ContentMigrationItem[]
  refetchMigrationItem: (contentMigrationItemId: string) => () => void
}

const ContentMigrationsTableCondensedView = ({
  migrations,
  refetchMigrationItem,
}: ContentMigrationsTableViewProps) => {
  return (
    <Flex direction="column" gap="small">
      {migrations.map((cm: ContentMigrationItem) => (
        <Flex.Item key={cm.id}>
          <View as="div" padding="small" background="secondary">
            <Grid as="table" vAlign="middle" rowSpacing="medium">
              <Grid.Row as="tr">
                <Grid.Col as="th" width={5}>
                  <Text weight="bold">{I18n.t('Content Type')}</Text>
                </Grid.Col>
                <Grid.Col as="td">
                  <Text>{cm.migration_type_title}</Text>
                </Grid.Col>
              </Grid.Row>
              <Grid.Row as="tr">
                <Grid.Col as="th" width={5}>
                  <Text weight="bold">{I18n.t('Source Link')}</Text>
                </Grid.Col>
                <Grid.Col as="td">
                  <SourceLink item={cm} />
                </Grid.Col>
              </Grid.Row>
              <Grid.Row as="tr">
                <Grid.Col as="th" width={5}>
                  <Text weight="bold">{I18n.t('Date Imported')}</Text>
                </Grid.Col>
                <Grid.Col as="td">
                  <Text>{datetimeString(cm.created_at, {timezone: ENV.CONTEXT_TIMEZONE})}</Text>
                </Grid.Col>
              </Grid.Row>
              <Grid.Row as="tr">
                <Grid.Col as="th" width={5}>
                  <Text weight="bold">{I18n.t('Status')}</Text>
                </Grid.Col>
                <Grid.Col as="td">
                  <StatusPill
                    hasIssues={cm.migration_issues_count !== 0}
                    workflowState={cm.workflow_state}
                  />
                </Grid.Col>
              </Grid.Row>
              <Grid.Row as="tr">
                <Grid.Col as="th" width={5}>
                  <Text weight="bold">{I18n.t('Progress')}</Text>
                </Grid.Col>
                <Grid.Col as="td">
                  {buildProgressCellContent(cm, refetchMigrationItem(cm.id))}
                </Grid.Col>
              </Grid.Row>
              <Grid.Row as="tr">
                <Grid.Col as="th" width={5}>
                  <Text weight="bold">{I18n.t('Action')}</Text>
                </Grid.Col>
                <Grid.Col as="td">
                  <ActionButton
                    migration_type_title={cm.migration_type_title}
                    migration_issues_count={cm.migration_issues_count}
                    migration_issues_url={cm.migration_issues_url}
                  />
                </Grid.Col>
              </Grid.Row>
            </Grid>
          </View>
        </Flex.Item>
      ))}
    </Flex>
  )
}

const ContentMigrationsTableExpandedView = ({
  migrations,
  refetchMigrationItem,
}: ContentMigrationsTableViewProps) => {
  return (
    <Table caption={I18n.t('Content Migrations')}>
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
          <Table.ColHeader themeOverride={{padding: '0.6rem 0'}} id="status">
            {I18n.t('Status')}
          </Table.ColHeader>
          <Table.ColHeader themeOverride={{padding: '0.6rem 0'}} id="progress">
            {I18n.t('Progress')}
          </Table.ColHeader>
          <Table.ColHeader themeOverride={{padding: '0.6rem 0'}} id="action">
            {I18n.t('Action')}
          </Table.ColHeader>
        </Table.Row>
      </Table.Head>
      <Table.Body>
        {migrations.map((cm: ContentMigrationItem) => (
          <Table.Row key={cm.id}>
            <Table.Cell themeOverride={{padding: '1.1rem 0rem'}}>
              {cm.migration_type_title}
            </Table.Cell>
            <Table.Cell>
              <SourceLink item={cm} />
            </Table.Cell>
            <Table.Cell>
              {datetimeString(cm.created_at, {timezone: ENV.CONTEXT_TIMEZONE})}
            </Table.Cell>
            <Table.Cell>
              <StatusPill
                hasIssues={cm.migration_issues_count !== 0}
                workflowState={cm.workflow_state}
              />
            </Table.Cell>
            <Table.Cell>{buildProgressCellContent(cm, refetchMigrationItem(cm.id))}</Table.Cell>
            <Table.Cell>
              <ActionButton
                migration_type_title={cm.migration_type_title}
                migration_issues_count={cm.migration_issues_count}
                migration_issues_url={cm.migration_issues_url}
              />
            </Table.Cell>
          </Table.Row>
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
  setMigrations: (migrations: ContentMigrationItem[]) => void
}) => {
  useEffect(() => {
    doFetchApi({
      path: `/api/v1/courses/${window.ENV.COURSE_ID}/content_migrations`,
      params: {per_page: 25},
    })
      .then((response: MigrationsResponse) => setMigrations(response.json))
      .catch(showFlashError(I18n.t("Couldn't load previous content migrations")))
  }, [setMigrations])

  const refetchMigrationItem = useCallback(
    (migrationId: string) => () => {
      doFetchApi({
        path: `/api/v1/courses/${window.ENV.COURSE_ID}/content_migrations/${migrationId}`,
      })
        .then((response: MigrationResponse) =>
          // I needed to do this to force re-render
          setMigrations(migrations.map(m => (m.id === migrationId ? response.json : m)))
        )
        .catch(showFlashError(I18n.t("Couldn't update content migrations")))
    },
    [migrations, setMigrations]
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
                refetchMigrationItem={refetchMigrationItem}
              />
            )
          } else {
            return (
              <ContentMigrationsTableCondensedView
                migrations={migrations}
                refetchMigrationItem={refetchMigrationItem}
              />
            )
          }
        }}
      />
    </>
  )
}

export default ContentMigrationsTable

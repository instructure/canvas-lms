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

import React, {useEffect, useCallback, useState} from 'react'
import type {
  ContentMigrationItem,
  ContentMigrationWorkflowState,
  ProgressWorkflowState,
  StatusPillState,
  UpdateMigrationItemType,
} from './types'
import {datetimeString} from '@canvas/datetime/date-functions'
import {Table} from '@instructure/ui-table'
import {Text} from '@instructure/ui-text'
import StatusPill from './status_pill'
import {ActionButton} from './action_button'
import {CompletionProgressBar} from './completion_progress_bar'
import {SourceLink} from './source_link'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {timeout} from './utils'
import {useScope as createI18nScope} from '@canvas/i18n'
import {ContentSelectionModal} from './content_selection_modal'

const I18n = createI18nScope('content_migrations_redesign')

const done_states = ['completed', 'failed', 'waiting_for_select']

type ContentMigrationsRowProps = {
  migration: ContentMigrationItem
  layout?: 'auto' | 'fixed' | 'stacked'
  updateMigrationItem: UpdateMigrationItemType
}

type CompletionProgressResponse = {
  id: number
  context_id: number
  context_type: string
  user_id: number
  tag: string
  completion: number
  workflow_state: ProgressWorkflowState
  created_at: string
  updated_at: string
  message: string | null
  url: string
}

const supportedContentMigrationWorkflowStates = [
  'failed',
  'waiting_for_select',
  'running',
  'completed',
  'queued',
]

const mapProgress = (cm_workflow_state: ContentMigrationWorkflowState): StatusPillState => {
  return supportedContentMigrationWorkflowStates.includes(cm_workflow_state)
    ? (cm_workflow_state as StatusPillState)
    : 'queued'
}

const MigrationRow = ({migration, layout = 'auto', updateMigrationItem}: ContentMigrationsRowProps) => {
  const [statusPillState, setStatusPillState] = useState<StatusPillState>(
    mapProgress(migration.workflow_state),
  )

  const fetchProgress = useCallback(async () => {
    const response = await doFetchApi({
      path: migration.progress_url,
      method: 'GET',
    })
    const json = response.json as CompletionProgressResponse
    await timeout(1000)
    if (!done_states.includes(json.workflow_state)) {
      updateMigrationItem?.(migration.id, {completion: json.completion}, true)
      setStatusPillState(json.workflow_state)
      await fetchProgress()
    } else {
      const updatedContentMigration = await updateMigrationItem?.(migration.id, {
        completion: json.completion,
      })
      // Do not set to 'completed' state if there is waiting for select with selective import
      if (updatedContentMigration?.workflow_state !== 'waiting_for_select') {
        setStatusPillState(json.workflow_state)
      }
    }
  }, [migration.id, migration.progress_url, updateMigrationItem])

  useEffect(() => {
    if (migration.progress_url && !done_states.includes(migration.workflow_state)) fetchProgress()
    if (migration.workflow_state === 'waiting_for_select') {
      setStatusPillState('waiting_for_select')
    }
  }, [fetchProgress, migration.progress_url, migration.workflow_state])

  migration.migration_type_title ||= I18n.t('Content Migration')

  const cellStyle = layout === 'stacked' ? {} : {padding: '1.1rem 0rem'}
  const conditionalCenterAlign = layout === 'stacked' ? 'start' : 'center'

  return (
    <Table.Row key={migration.id}>
      <Table.Cell themeOverride={cellStyle}>{migration.migration_type_title}</Table.Cell>
      <Table.Cell themeOverride={cellStyle}>
        <SourceLink item={migration} ellipsis={layout !== 'stacked'}/>
      </Table.Cell>
      <Table.Cell themeOverride={cellStyle}>
        {datetimeString(migration.created_at, {timezone: ENV.CONTEXT_TIMEZONE})}
      </Table.Cell>
      <Table.Cell themeOverride={cellStyle} textAlign={conditionalCenterAlign}>
        <StatusPill
          hasIssues={migration.migration_issues_count !== 0}
          workflowState={statusPillState}
        />
      </Table.Cell>
      <Table.Cell themeOverride={cellStyle} textAlign={conditionalCenterAlign}>
        {['failed', 'completed'].includes(migration.workflow_state) &&
        migration.migration_issues_count > 0 ? (
          <Text>{I18n.t('%{count} issues', {count: migration.migration_issues_count})}</Text>
        ) : null}
        <CompletionProgressBar
          workflowState={migration.workflow_state}
          completion={migration.completion}
        />
        <ContentSelectionModal
          courseId={ENV.COURSE_ID}
          migration={migration}
          updateMigrationItem={updateMigrationItem}
        />
      </Table.Cell>
      <Table.Cell themeOverride={cellStyle} textAlign={conditionalCenterAlign}>
        <ActionButton
          migration_type_title={migration.migration_type_title}
          migration_issues_count={migration.migration_issues_count}
          migration_issues_url={migration.migration_issues_url}
        />
      </Table.Cell>
    </Table.Row>
  )
}
MigrationRow.displayName = 'Row'


export default MigrationRow

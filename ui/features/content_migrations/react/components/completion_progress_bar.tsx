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

import React, {useCallback, useEffect, useState, useRef} from 'react'
import {ProgressBar} from '@instructure/ui-progress'
import {Text} from '@instructure/ui-text'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {useScope as useI18nScope} from '@canvas/i18n'
import type {ContentMigrationItem} from './types'
import {ContentSelectionModal} from './content_selection_modal'

const I18n = useI18nScope('content_migrations_redesign')

type CompletionProgressWorkflowState = 'queued' | 'running' | 'completed' | 'failed'

type CompletionProgressResponse = {
  id: number
  context_id: number
  context_type: string
  user_id: number
  tag: string
  completion: number
  workflow_state: CompletionProgressWorkflowState
  created_at: string
  updated_at: string
  message: string | null
  url: string
}

type CompletionProgressBarProps = {
  progress_url: string
  onProgressFinish?: () => void
}

export const CompletionProgressBar = ({
  progress_url,
  onProgressFinish,
}: CompletionProgressBarProps) => {
  const [response, setResponse] = useState<CompletionProgressResponse | null>(null)
  const fetchIntervalRef = useRef<any>(null)

  const fetchProgress = useCallback(
    () =>
      progress_url &&
      doFetchApi({path: progress_url, method: 'GET'})
        .then(({json}: {json: CompletionProgressResponse}) => setResponse(json))
        .catch(() => setResponse(null)),
    [progress_url]
  )

  useEffect(() => {
    fetchProgress()

    // Fetch progress every second
    fetchIntervalRef.current = setInterval(fetchProgress, 1000)

    // Clearing interval when component is umounted
    return () => clearInterval(fetchIntervalRef.current)
  }, [fetchProgress, progress_url])

  useEffect(() => {
    // Stop fetching when response returned completed or failed
    if (response && ['completed', 'failed'].includes(response.workflow_state)) {
      onProgressFinish?.()
      clearInterval(fetchIntervalRef.current)
    }
  }, [response, onProgressFinish])

  // Renders null the first time until we get the response
  if (
    !progress_url ||
    !response ||
    ['queued', 'completed', 'failed'].includes(response.workflow_state)
  ) {
    return null
  }
  return (
    <ProgressBar
      size="small"
      meterColor="info"
      screenReaderLabel={I18n.t('Loading completion')}
      valueNow={response.completion}
      valueMax={100}
      // @ts-ignore
      shouldAnimate={true}
    />
  )
}

export const buildProgressCellContent = (
  {id, workflow_state, migration_issues_count, progress_url}: ContentMigrationItem,
  onReloadMigrationItem: () => void
) => {
  const courseId = ENV.COURSE_ID
  if (['failed', 'completed'].includes(workflow_state) && migration_issues_count > 0) {
    return <Text>{I18n.t('%{count} issues', {count: migration_issues_count})}</Text>
  } else if (workflow_state === 'running') {
    return (
      <CompletionProgressBar progress_url={progress_url} onProgressFinish={onReloadMigrationItem} />
    )
  } else if (courseId && workflow_state === 'waiting_for_select') {
    return (
      <ContentSelectionModal
        courseId={courseId}
        migrationId={id}
        onSubmit={onReloadMigrationItem}
      />
    )
  }
  // Return null for pre_processing
  return null
}

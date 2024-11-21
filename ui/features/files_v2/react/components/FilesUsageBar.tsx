/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {useQuery} from '@tanstack/react-query'
import {useScope as useI18nScope} from '@canvas/i18n'
import {ProgressBar} from '@instructure/ui-progress'
import {Text} from '@instructure/ui-text'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import formatMessage from '../../../../../packages/canvas-media/src/format-message'
import friendlyBytes from '@canvas/files/util/friendlyBytes'

const I18n = useI18nScope('files_v2')

const fetchQuota = async (contextType: string, contextId: string) => {
  const response = await fetch(`/api/v1/${contextType}/${contextId}/files/quota`)
  if (!response.ok) {
    throw new Error('Failed to fetch quota data')
  }
  return response.json()
}

interface FilesUsageBarProps {
  contextType: string
  contextId: string
}

const FilesUsageBar = ({contextType, contextId}: FilesUsageBarProps) => {
  const {data, error, isLoading} = useQuery(['quota'], () => fetchQuota(contextType, contextId))

  if (error) {
    showFlashError(I18n.t('An error occurred while loading files usage data'))(error as Error)
    return null
  }

  if (isLoading) {
    return null
  }

  const {quota_used = 0, quota = 1} = data || {quota_used: 0, quota: 1}
  const percentage = Math.round((quota_used / quota) * 100)

  const filesUsageString = I18n.t('%{percentUsed} of %{quota} used', {
    percentUsed: I18n.n(percentage, {percentage: true}),
    quota: friendlyBytes(data?.quota) || 0,
  })

  return (
    <ProgressBar
      meterColor="brand"
      screenReaderLabel={formatMessage('File Storage Quota Used')}
      formatScreenReaderValue={() => filesUsageString}
      renderValue={<Text>{filesUsageString}</Text>}
      size="x-small"
      valueMax={quota}
      valueNow={quota_used}
    />
  )
}

export default FilesUsageBar

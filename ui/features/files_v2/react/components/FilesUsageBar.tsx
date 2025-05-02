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

import React, {useEffect} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {ProgressBar} from '@instructure/ui-progress'
import {Text} from '@instructure/ui-text'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import formatMessage from '../../../../../packages/canvas-media/src/format-message'
import friendlyBytes from '@canvas/files/util/friendlyBytes'
import {useFileManagement} from '../contexts/FileManagementContext'
import {Flex} from '@instructure/ui-flex'
import {useGetQuota} from '../hooks/useGetQuota'

const I18n = createI18nScope('files_v2')

const FilesUsageBar = () => {
  const {contextType, contextId} = useFileManagement()
  const {data, error, isLoading} = useGetQuota(contextType, contextId)

  useEffect(() => {
    if (error) {
      showFlashError(I18n.t('An error occurred while loading files usage data.'))()
    }
  }, [error])

  if (isLoading || error) {
    return null
  }

  const {quota_used = 0, quota = 1} = data || {quota_used: 0, quota: 1}
  const filesUsageString = I18n.t('%{used} of %{quota} used', {
    used: friendlyBytes(quota_used),
    quota: friendlyBytes(data?.quota) || 0,
  })

  return (
    <Flex direction="column" gap="x-small">
      <ProgressBar
        meterColor="brand"
        screenReaderLabel={formatMessage('File Storage Quota Used')}
        formatScreenReaderValue={() => filesUsageString}
        size="x-small"
        valueMax={quota}
        valueNow={quota_used}
      />
      <Text data-testid="files-usage-text">{filesUsageString}</Text>
    </Flex>
  )
}

export default FilesUsageBar

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
import {Heading} from '@instructure/ui-heading'
import {useScope as useI18nScope} from '@canvas/i18n'
import {ProgressBar} from '@instructure/ui-progress'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import filesEnv from '@canvas/files/react/modules/filesEnv'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import formatMessage from '../../../../../packages/canvas-media/src/format-message'
import friendlyBytes from '@canvas/files/util/friendlyBytes'

const I18n = useI18nScope('files_v2')

interface FilesAppProps {
  contextAssetString: string
}

const fetchQuota = async (contextType: string, contextId: string) => {
  const response = await fetch(`/api/v1/${contextType}/${contextId}/files/quota`)
  if (!response.ok) {
    throw new Error('Failed to fetch quota data')
  }
  return response.json()
}

const FilesApp: React.FC<FilesAppProps> = ({contextAssetString}) => {
  const contextType = filesEnv.contextType
  const contextId = filesEnv.contextId
  const isUserContext = contextAssetString?.startsWith('user_')

  const {data, error} = useQuery(['quota'], () => fetchQuota(contextType, contextId))

  const renderFilesUsageValue = (percentage: number) => {
    return (
      <Text>
        {I18n.t('%{percentUsed} of %{quota} used', {
          percentUsed: I18n.n(percentage, {percentage: true}),
          quota: friendlyBytes(data?.quota) || 0,
        })}
      </Text>
    )
  }

  const renderFilesUsageBar = () => {
    if (error) {
      showFlashError(I18n.t('An error occurred while loading files usage data'))(error)
    }

    const {quota_used = 0, quota = 1} = data || {quota_used: 0, quota: 1}
    const percentage = Math.round((quota_used / quota) * 100)

    return (
      <ProgressBar
        meterColor="brand"
        screenReaderLabel={formatMessage('File Storage Quota Used')}
        formatScreenReaderValue={() => renderFilesUsageValue(percentage)}
        renderValue={renderFilesUsageValue(percentage)}
        size="x-small"
        valueMax={quota}
        valueNow={quota_used}
      />
    )
  }

  return (
    <div>
      <Heading level="h1">{isUserContext ? I18n.t('All My Files') : I18n.t('Files')}</Heading>
      <View as="div">
        <Flex>
          <Flex.Item size="50%">{renderFilesUsageBar()}</Flex.Item>
        </Flex>
      </View>
    </div>
  )
}

export default FilesApp

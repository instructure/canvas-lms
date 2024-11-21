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
import {View} from '@instructure/ui-view'
import filesEnv from '@canvas/files/react/modules/filesEnv'
import {Flex} from '@instructure/ui-flex'
import {canvas} from '@instructure/ui-theme-tokens'
import {Responsive} from '@instructure/ui-responsive'

import TopLevelButtons from './TopLevelButtons'
import FileFolderTable from './FileFolderTable'

import {FAKE_FOLDERS_AND_FILES} from '../../data/FakeData'
import FilesUsageBar from './FilesUsageBar'

const I18n = useI18nScope('files_v2')

const fetchFilesAndFolders = async (contextType: string, contextId: string) => {
  // TODO fetch real data
  return FAKE_FOLDERS_AND_FILES
}

interface FilesAppProps {
  isUserContext: boolean
  size: 'small' | 'medium' | 'large'
}

const FilesApp = ({isUserContext, size}: FilesAppProps) => {
  const contextType = filesEnv.contextType
  const contextId = filesEnv.contextId

  const canManageFilesForContext = (permission: string) => {
    // @ts-expect-error
    return filesEnv.userHasPermission({contextType, contextId}, permission)
  }

  const userCanAddFilesForContext = canManageFilesForContext('manage_files_add')
  const userCanEditFilesForContext = canManageFilesForContext('manage_files_edit')
  const userCanDeleteFilesForContext = canManageFilesForContext('manage_files_delete')
  const userCanManageFilesForContext =
    userCanAddFilesForContext || userCanEditFilesForContext || userCanDeleteFilesForContext

  const tableResult = useQuery(['files'], () => fetchFilesAndFolders(contextType, contextId))

  return (
    <View as="div">
      <Flex justifyItems="center" padding="medium none none none">
        <Flex.Item shouldShrink={true} shouldGrow={true} textAlign="center">
          <Flex
            wrap="wrap"
            margin="0 0 medium"
            justifyItems="space-between"
            direction={size === 'large' ? 'row' : 'column'}
          >
            <Flex.Item padding="small small small none" align="start">
              <Heading level="h1">
                {isUserContext ? I18n.t('All My Files') : I18n.t('Files')}
              </Heading>
            </Flex.Item>
            <Flex.Item
              padding="xx-small"
              direction={size === 'small' ? 'column' : 'row'}
              align={size === 'medium' ? 'start' : undefined}
              overflowX="hidden"
            >
              <TopLevelButtons size={size} isUserContext={isUserContext} />
            </Flex.Item>
          </Flex>
        </Flex.Item>
      </Flex>
      <FileFolderTable
        size={size}
        rows={tableResult.isSuccess ? tableResult.data : undefined}
        isLoading={tableResult.isLoading}
        userCanEditFilesForContext={userCanEditFilesForContext}
      />
      {userCanManageFilesForContext && (
        <Flex padding="small none none none">
          <Flex.Item size="50%">
            <FilesUsageBar contextId={contextId} contextType={contextType} />
          </Flex.Item>
        </Flex>
      )}
    </View>
  )
}
interface ResponsiveFilesAppProps {
  contextAssetString: string
}

const ResponsiveFilesApp = ({contextAssetString}: ResponsiveFilesAppProps) => {
  const isUserContext = contextAssetString.startsWith('user_')

  return (
    <Responsive
      match="media"
      query={{
        small: {maxWidth: canvas.breakpoints.small},
        medium: {maxWidth: canvas.breakpoints.tablet},
      }}
      render={(_props: any, matches: string[] | undefined) => (
        <FilesApp
          isUserContext={isUserContext}
          size={(matches?.[0] as 'small' | 'medium') || 'large'}
        />
      )}
    />
  )
}
export default ResponsiveFilesApp

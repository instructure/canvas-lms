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
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import filesEnv from '@canvas/files_v2/react/modules/filesEnv'
import {Flex} from '@instructure/ui-flex'
import {canvas} from '@instructure/ui-theme-tokens'
import {Responsive} from '@instructure/ui-responsive'

import FilesHeader from './FilesHeader'
import FileFolderTable from './FileFolderTable'
import FilesUsageBar from './FilesUsageBar'
import {useLoaderData} from 'react-router-dom'
import {type Folder} from '../../interfaces/File'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {FileManagementContext} from './Contexts'

const I18n = createI18nScope('files_v2')

interface FilesAppProps {
  isUserContext: boolean
  size: 'small' | 'medium' | 'large'
}

const FilesApp = ({isUserContext, size}: FilesAppProps) => {
  const folders = useLoaderData() as Folder[] | null
  if (!folders || folders.length === 0) {
    showFlashError(I18n.t('Failed to retrieve folder information'))
    return null
  }
  const currentFolder = folders[folders.length - 1]
  const folderId = currentFolder.id
  const contextId = currentFolder.context_id
  const contextType = currentFolder.context_type.toLowerCase()
  const canManageFilesForContext = (permission: string) => {
    return filesEnv.userHasPermission({contextType, contextId}, permission)
  }
  const userCanAddFilesForContext = canManageFilesForContext('manage_files_add')
  const userCanEditFilesForContext = canManageFilesForContext('manage_files_edit')
  const userCanDeleteFilesForContext = canManageFilesForContext('manage_files_delete')
  const userCanManageFilesForContext =
    userCanAddFilesForContext || userCanEditFilesForContext || userCanDeleteFilesForContext

  return (
    <FileManagementContext.Provider value={{folderId, contextType, contextId}}>
      <View as="div">
        <FilesHeader size={size} isUserContext={isUserContext} />
        <FileFolderTable size={size} userCanEditFilesForContext={userCanEditFilesForContext} />
        {userCanManageFilesForContext && (
          <Flex padding="small none none none">
            <Flex.Item size="50%">
              <FilesUsageBar />
            </Flex.Item>
          </Flex>
        )}
      </View>
    </FileManagementContext.Provider>
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

/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import BreadcrumbLinkWithTip from './BreadcrumbLinkWithTip'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import FileSelectTable from './FileSelectTable'
import GenericErrorPage from '@canvas/generic-error-page'
import {useScope as createI18nScope} from '@canvas/i18n'
import LoadingIndicator from '@canvas/loading-indicator'
import {useCanvasFileBrowser} from './hooks/useCanvasFileBrowser'
import {buildBreadcrumbPath} from './utils/folderHelpers'

import {Breadcrumb} from '@instructure/ui-breadcrumb'
import {Flex} from '@instructure/ui-flex'

const I18n = createI18nScope('canvas_file_upload')

interface CanvasFilesBrowserProps {
  allowedExtensions?: string[]
  courseID: string
  handleCanvasFileSelect: (fileID: string) => void
}

const CanvasFilesBrowser: React.FC<CanvasFilesBrowserProps> = ({
  allowedExtensions,
  courseID,
  handleCanvasFileSelect,
}) => {
  const {
    loadedFolders,
    loadedFiles,
    error,
    isLoading,
    selectedFolderID,
    handleUpdateSelectedFolder,
  } = useCanvasFileBrowser({courseID})

  const renderFolderPathBreadcrumb = () => {
    if (!selectedFolderID) return null

    const path = buildBreadcrumbPath(selectedFolderID, loadedFolders)

    return (
      <Flex.Item padding="medium xx-small xx-small xx-small">
        <Breadcrumb label={I18n.t('current folder path')}>
          {path.map((currentFolder, i) => {
            // special case to make the last folder in the path (i.e. the current folder)
            // not a link
            if (i === path.length - 1) {
              return (
                <BreadcrumbLinkWithTip
                  key={currentFolder.id}
                  {...({tip: currentFolder.name} as any)}
                >
                  {currentFolder.name}
                </BreadcrumbLinkWithTip>
              )
            }
            return (
              <BreadcrumbLinkWithTip
                key={currentFolder.id}
                {...({
                  tip: currentFolder.name,
                  onClick: () => handleUpdateSelectedFolder(currentFolder.id),
                } as any)}
              >
                {currentFolder.name}
              </BreadcrumbLinkWithTip>
            )
          })}
        </Breadcrumb>
      </Flex.Item>
    )
  }

  if (error) {
    return (
      <GenericErrorPage
        imageUrl={errorShipUrl}
        errorSubject={error.message}
        errorCategory={I18n.t('Canvas File Browser Error')}
      />
    )
  }

  if (!selectedFolderID) {
    return (
      <Flex direction="column" justifyItems="center" alignItems="center" padding="large">
        <LoadingIndicator />
      </Flex>
    )
  }

  return (
    <Flex direction="column" data-testid="canvas-files-browser">
      {renderFolderPathBreadcrumb()}
      <Flex.Item>
        <FileSelectTable
          allowedExtensions={allowedExtensions}
          folders={loadedFolders}
          files={loadedFiles}
          selectedFolderID={selectedFolderID}
          handleCanvasFileSelect={handleCanvasFileSelect}
          handleFolderSelect={handleUpdateSelectedFolder}
        />
      </Flex.Item>
      {isLoading && (
        <Flex.Item>
          <LoadingIndicator />
        </Flex.Item>
      )}
    </Flex>
  )
}

export default CanvasFilesBrowser

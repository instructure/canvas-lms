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

import React, {useCallback, useEffect, useRef, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import filesEnv from '@canvas/files_v2/react/modules/filesEnv'
import {Flex} from '@instructure/ui-flex'
import {canvas} from '@instructure/ui-theme-tokens'
import {Responsive} from '@instructure/ui-responsive'
import {Pagination} from '@instructure/ui-pagination'
import FilesHeader from './FilesHeader'
import FileFolderTable from './FileFolderTable'
import FilesUsageBar from './FilesUsageBar'
import {useLoaderData} from 'react-router-dom'
import {type Folder} from '../../interfaces/File'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {FileManagementContext} from './Contexts'
import {MainFolderWrapper} from '../../utils/fileFolderWrappers'
import SearchBar from './SearchBar'
import {Alert} from '@instructure/ui-alerts'

const I18n = createI18nScope('files_v2')

interface FilesAppProps {
  isUserContext: boolean
  size: 'small' | 'medium' | 'large'
}

const FilesApp = ({isUserContext, size}: FilesAppProps) => {
  const showingAllContexts = filesEnv.showingAllContexts
  const [isTableLoading, setIsTableLoading] = useState(true)
  const [currentPageNumber, setCurrentPageNumber] = useState(1)
  const [sortBy, setSortBy] = useState<string>('name')
  const [sortDirection, setSortDirection] = useState<string>('asc')
  const [currentUrl, setCurrentUrl] = useState<string>('')
  const [discoveredPages, setDiscoveredPages] = useState<{[key: number]: string}>({})
  const [paginationSRText, setPaginationSRText] = useState<string>('')
  const {folders, searchTerm} = useLoaderData() as {folders: Folder[] | null; searchTerm: string}
  const currentFolderWrapper = useRef<MainFolderWrapper | null>(null)

  // the useEffect is necessary to protect against folders being empty
  useEffect(() => {
    if (!folders || folders.length === 0) return

    const currentFolder = folders[folders.length - 1]
    const folderId = currentFolder.id
    const contextId = currentFolder.context_id
    const contextType = currentFolder.context_type.toLowerCase()
    let baseUrl
    if (searchTerm) {
      baseUrl = `/api/v1/${contextType}s/${contextId}/files?search_term=${searchTerm}&per_page=50&include[]=user&include[]=usage_rights&include[]=enhanced_preview_url&include[]=context_asset_string&include[]=blueprint_course_status`
    } else {
      baseUrl = `/api/v1/folders/${folderId}/all?include[]=user&include[]=usage_rights&include[]=enhanced_preview_url&include[]=context_asset_string&include[]=blueprint_course_status`
    }

    const newCurrentUrl = `${baseUrl}&sort=${sortBy}&order=${sortDirection}`
    setCurrentUrl(newCurrentUrl)
    setDiscoveredPages({1: newCurrentUrl})
    setCurrentPageNumber(1)

    currentFolderWrapper.current = new MainFolderWrapper(currentFolder)
  }, [folders, searchTerm, sortBy, sortDirection])

  const handleTableLoadingStatusChange = useCallback((isLoading: boolean) => {
    setIsTableLoading(isLoading)
  }, [])

  const handlePaginationLinkChange = useCallback(
    (links: Record<string, string>) => {
      let srTotalPageNumber = Object.keys(discoveredPages).length
      if (links.next && !discoveredPages[currentPageNumber + 1]) {
        setDiscoveredPages(prev => {
          const newLinks = {...prev, [currentPageNumber + 1]: links.next}
          return newLinks
        })
        srTotalPageNumber++
      }

      setPaginationSRText(
        I18n.t('Table page %{currentPageNumber} of %{totalPageNumber}', {
          currentPageNumber,
          totalPageNumber: srTotalPageNumber,
        }),
      )
    },
    [currentPageNumber, discoveredPages],
  )

  const handlePageChange = useCallback(
    (pageNumber: number) => {
      setCurrentPageNumber(pageNumber)
      setCurrentUrl(discoveredPages[pageNumber])
    },
    [discoveredPages],
  )

  const handlesortChange = useCallback((newSortBy: string, newSortDirection: string) => {
    setSortBy(newSortBy)
    setSortDirection(newSortDirection)
  }, [])

  if (!folders || folders.length === 0) {
    showFlashError(I18n.t('Failed to retrieve folder information'))
    return null
  }

  const totalPageNumber = Object.keys(discoveredPages).length
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
  const usageRightsRequiredForContext =
    filesEnv.contextFor({contextType, contextId})?.usage_rights_required || false

  return (
    <FileManagementContext.Provider
      value={{
        folderId,
        contextType,
        contextId,
        showingAllContexts,
        currentFolder: currentFolderWrapper.current,
      }}
    >
      <View as="div">
        <FilesHeader
          size={size}
          isUserContext={isUserContext}
          shouldHideUploadButtons={!userCanAddFilesForContext}
        />
        <SearchBar initialValue={searchTerm} />
        {currentUrl && (
          <FileFolderTable
            size={size}
            folderBreadcrumbs={folders}
            userCanEditFilesForContext={userCanEditFilesForContext}
            userCanDeleteFilesForContext={userCanDeleteFilesForContext}
            usageRightsRequiredForContext={usageRightsRequiredForContext}
            currentUrl={currentUrl}
            onPaginationLinkChange={handlePaginationLinkChange}
            onLoadingStatusChange={handleTableLoadingStatusChange}
            onSortChange={handlesortChange}
            searchString={searchTerm}
          />
        )}
        <Flex padding="small none none none" justifyItems="space-between">
          <Flex.Item size="50%">{userCanManageFilesForContext && <FilesUsageBar />}</Flex.Item>
          <Flex.Item size="auto" padding="none medium none none">
            <Alert
              liveRegion={() => document.getElementById('flash_screenreader_holder')!}
              liveRegionPoliteness="polite"
              screenReaderOnly
              data-testid="pagination-announcement"
            >
              {paginationSRText}
            </Alert>
            {!isTableLoading && totalPageNumber > 1 && (
              <Pagination
                as="nav"
                labelNext="Next page"
                labelPrev="Previous page"
                variant="compact"
                currentPage={currentPageNumber}
                totalPageNumber={totalPageNumber}
                onPageChange={handlePageChange}
                data-testid="files-pagination"
              />
            )}
          </Flex.Item>
        </Flex>
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

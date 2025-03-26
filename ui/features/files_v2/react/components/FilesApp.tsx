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
import {useLoaderData} from 'react-router-dom'

import {Alert} from '@instructure/ui-alerts'
import {Flex} from '@instructure/ui-flex'
import {Pagination} from '@instructure/ui-pagination'
import {Responsive} from '@instructure/ui-responsive'
import {canvas} from '@instructure/ui-theme-tokens'
import {View} from '@instructure/ui-view'

import {useScope as createI18nScope} from '@canvas/i18n'
import filesEnv from '@canvas/files_v2/react/modules/filesEnv'

import {FileManagementProvider} from './Contexts'
import FileFolderTable from './FileFolderTable'
import FilesHeader from './FilesHeader'
import FilesUsageBar from './FilesUsageBar'
import SearchBar from './SearchBar'
import {generateTableUrl} from '../../utils/apiUtils'
import {BBFolderWrapper} from '../../utils/fileFolderWrappers'
import {LoaderData} from '../../interfaces/LoaderData'

const I18n = createI18nScope('files_v2')

interface FilesAppProps {
  isUserContext: boolean
  size: 'small' | 'medium' | 'large'
}

const FilesApp = ({isUserContext, size}: FilesAppProps) => {
  const showingAllContexts = filesEnv.showingAllContexts
  const {folders, searchTerm} = useLoaderData() as LoaderData
  const [isTableLoading, setIsTableLoading] = useState(true)
  const [sort, setSort] = useState({
    sortBy: 'name',
    sortDirection: 'asc',
  })
  const [currentPageNumber, setCurrentPageNumber] = useState(1)
  const [pageQueryBookmarks, setPageQueryBookmarks] = useState<{[key: number]: string}>({1: ''})
  const [paginationAlert, setPaginationAlert] = useState<string>('')
  const currentFolderWrapper = useRef<BBFolderWrapper | null>(null)

  const currentFolder = folders[folders.length - 1]
  const folderId = currentFolder.id
  const contextId = currentFolder.context_id
  const contextType = currentFolder.context_type.toLowerCase()
  const totalPageNumber = Object.keys(pageQueryBookmarks).length

  const currentUrl = generateTableUrl({
    searchTerm,
    contextId,
    contextType,
    folderId,
    sortBy: sort.sortBy,
    sortDirection: sort.sortDirection,
    pageQueryParam: pageQueryBookmarks[currentPageNumber],
  })

  useEffect(() => {
    setPageQueryBookmarks({1: ''})
    setCurrentPageNumber(1)
    currentFolderWrapper.current = new BBFolderWrapper(currentFolder)
  }, [currentFolder])

  const handleTableLoadingStatusChange = useCallback((isLoading: boolean) => {
    setIsTableLoading(isLoading)
  }, [])

  const handlePaginationLinkChange = useCallback(
    (links: Record<string, string>) => {
      let srTotalPageNumber = Object.keys(pageQueryBookmarks).length
      if (links.next && !pageQueryBookmarks[currentPageNumber + 1]) {
        const url = new URL(links.next)
        const searchParams = url.searchParams
        const pageQueryParam = searchParams.get('page') || ''
        setPageQueryBookmarks(prev => {
          const newBookmarks = {...prev, [currentPageNumber + 1]: pageQueryParam}
          return newBookmarks
        })
        srTotalPageNumber++
      }

      setPaginationAlert(
        I18n.t('Table page %{currentPageNumber} of %{totalPageNumber}', {
          currentPageNumber,
          totalPageNumber: srTotalPageNumber,
        }),
      )
    },
    [currentPageNumber, pageQueryBookmarks],
  )

  const handlePageChange = useCallback((pageNumber: number) => {
    setCurrentPageNumber(pageNumber)
  }, [])

  const handleSortChange = useCallback((newSortBy: string, newSortDirection: string) => {
    setSort({sortBy: newSortBy, sortDirection: newSortDirection})
    setCurrentPageNumber(1)
    setPageQueryBookmarks({1: ''})
  }, [])

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
  const fileIndexMenuTools =
    filesEnv.contextFor({contextType, contextId})?.file_index_menu_tools || []
  const fileMenuTools = filesEnv.contextFor({contextType, contextId})?.file_menu_tools || []

  return (
    <FileManagementProvider
      value={{
        folderId,
        contextType,
        contextId,
        showingAllContexts,
        currentFolder: currentFolderWrapper.current,
        rootFolder: folders[0],
        fileIndexMenuTools,
        fileMenuTools,
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
            onSortChange={handleSortChange}
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
              {paginationAlert}
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
    </FileManagementProvider>
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

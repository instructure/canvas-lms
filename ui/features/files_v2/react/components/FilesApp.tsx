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
import {Alert} from '@instructure/ui-alerts'
import {Pagination} from '@instructure/ui-pagination'
import {Responsive} from '@instructure/ui-responsive'
import {canvas} from '@instructure/ui-themes'

import {useScope as createI18nScope} from '@canvas/i18n'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {Checkbox} from '@instructure/ui-checkbox'
import {getFilesEnv} from '../../utils/filesEnvUtils'
import {FileManagementProvider} from '../contexts/FileManagementContext'
import {RowFocusProvider, SELECT_ALL_FOCUS_STRING} from '../contexts/RowFocusContext'
import {RowsProvider} from '../contexts/RowsContext'
import FileFolderTable from './FileFolderTable'
import FilesUsageBar from './FilesUsageBar'
import SearchBar from './SearchBar'
import {BBFolderWrapper, FileFolderWrapper} from '../../utils/fileFolderWrappers'
import {NotFoundError, UnauthorizedError} from '../../utils/apiUtils'
import {useGetFolders} from '../hooks/useGetFolders'
import {File, Folder} from '../../interfaces/File'
import {useGetPaginatedFiles} from '../hooks/useGetPaginatedFiles'
import {FilesLayout} from '../layouts/FilesLayout'
import TopLevelButtons from './FilesHeader/TopLevelButtons'
import Breadcrumbs from './FileFolderTable/Breadcrumbs'
import BulkActionButtons from './FileFolderTable/BulkActionButtons'
import CurrentUploads from './FilesHeader/CurrentUploads'
import CurrentDownloads from './FilesHeader/CurrentDownloads'
import NotFoundArtwork from '@canvas/generic-error-page/react/NotFoundArtwork'

const I18n = createI18nScope('files_v2')

interface FilesAppProps {
  folders: Folder[]
  isUserContext: boolean
  size: 'small' | 'medium' | 'large'
}

const FilesApp = ({folders, isUserContext, size}: FilesAppProps) => {
  const filesEnv = getFilesEnv()
  const showingAllContexts = filesEnv.showingAllContexts

  const [currentRows, setCurrentRows] = useState<(File | Folder)[]>([])
  const [paginationAlert, setPaginationAlert] = useState<string>('')
  const [rowToFocus, setRowToFocus] = useState<number | SELECT_ALL_FOCUS_STRING | null>(null)
  const currentFolderWrapper = useRef<BBFolderWrapper | null>(null)
  const fileDropRef = useRef<HTMLInputElement | null>(null)
  const selectAllRef = useRef<Checkbox | null>(null)
  const actionButtonRefArray = useRef<React.RefObject<HTMLElement>[]>([])

  const handleFileDropRef = (el: HTMLInputElement | null) => {
    fileDropRef.current = el
  }
  const handleActionButtonRef = (el: HTMLElement | null, i: number) => {
    actionButtonRefArray.current[i] = {current: el}
  }

  const currentFolder = folders[folders.length - 1]
  const folderId = currentFolder.id.toString()
  const contextId = currentFolder.context_id
  const contextType = currentFolder.context_type.toLowerCase()

  const onSettled = useCallback(
    (rows: (File | Folder)[]) => {
      const currentFolderId = currentFolderWrapper.current?.id
      if (currentFolderId !== currentFolder.id) {
        currentFolderWrapper.current = new BBFolderWrapper(currentFolder)
      }
      currentFolderWrapper.current!.files.set(rows.map((row: any) => new FileFolderWrapper(row)))
      setCurrentRows(rows)
    },
    [currentFolder],
  )

  const {
    data: rows,
    isFetching: isLoading,
    error,
    page,
    search,
    sort,
  } = useGetPaginatedFiles({
    folder: currentFolder,
    onSettled,
  })

  // used to set focus after a move or delete action
  useEffect(() => {
    if (rowToFocus != null && !isLoading) {
      if (currentRows?.length === 0) {
        // empty table, focus on file drop
        fileDropRef.current?.focus()
      } else if (rowToFocus === SELECT_ALL_FOCUS_STRING) {
        selectAllRef.current?.focus()
      } else if (currentRows?.length) {
        // focus on the next row from the row just moved or deleted
        const rowToFocusIndex =
          rowToFocus >= currentRows.length ? currentRows.length - 1 : rowToFocus
        const menu = actionButtonRefArray.current[rowToFocusIndex]?.current
        const focusable = menu?.querySelector('button')
        ;(focusable as HTMLElement)?.focus()
      }
      setRowToFocus(null)
    }
  }, [rowToFocus, isLoading, currentRows?.length])

  useEffect(() => {
    if (error instanceof UnauthorizedError) {
      window.location.href = '/login'
    } else if (error) {
      showFlashError(I18n.t('Failed to fetch files and folders.'))()
    }
  }, [error])

  useEffect(() => {
    if (!isLoading) {
      setPaginationAlert(
        I18n.t('Table page %{current} of %{total}', {
          current: page.current,
          total: page.total,
        }),
      )
    }
  }, [isLoading, page.current, page.total])

  const canManageFilesForContext = (permission: string) => {
    return filesEnv.userHasPermission({contextType, contextId}, permission)
  }
  const userCanAddFilesForContext = canManageFilesForContext('manage_files_add')
  const userCanEditFilesForContext = canManageFilesForContext('manage_files_edit')
  const userCanDeleteFilesForContext = canManageFilesForContext('manage_files_delete')
  const userCanRestrictFilesForContext = userCanEditFilesForContext && contextType !== 'group'
  const userCanManageFilesForContext =
    userCanAddFilesForContext || userCanEditFilesForContext || userCanDeleteFilesForContext
  const usageRightsRequiredForContext =
    filesEnv.contextFor({contextType, contextId})?.usage_rights_required || false
  const fileIndexMenuTools =
    filesEnv.contextFor({contextType, contextId})?.file_index_menu_tools || []
  const fileMenuTools = filesEnv.contextFor({contextType, contextId})?.file_menu_tools || []

  const [selectedRows, setSelectedRows] = useState<Set<string>>(new Set())
  useEffect(() => {
    setSelectedRows(new Set())
  }, [rows])

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
      <RowFocusProvider value={{setRowToFocus, handleActionButtonRef}}>
        <RowsProvider value={{setCurrentRows, currentRows}}>
          <FilesLayout
            size={size}
            title={I18n.t('Files')}
            headerActions={
              <TopLevelButtons
                size={size}
                isUserContext={isUserContext}
                shouldHideUploadButtons={!userCanAddFilesForContext || search.term.length > 0}
              />
            }
            search={<SearchBar initialValue={search.term} onSearch={search.set} />}
            breadcrumbs={<Breadcrumbs folders={folders} size={size} search={search.term} />}
            bulkActions={
              <BulkActionButtons
                size={size}
                selectedRows={selectedRows}
                rows={currentRows ?? []}
                totalRows={currentRows?.length ?? 0}
                userCanEditFilesForContext={userCanEditFilesForContext}
                userCanDeleteFilesForContext={userCanDeleteFilesForContext}
                userCanRestrictFilesForContext={userCanRestrictFilesForContext}
                usageRightsRequiredForContext={usageRightsRequiredForContext}
              />
            }
            progress={
              <>
                <CurrentUploads />
                <CurrentDownloads rows={currentRows ?? []} />
              </>
            }
            table={
              <FileFolderTable
                size={size}
                rows={isLoading ? [] : currentRows!}
                isLoading={isLoading}
                userCanEditFilesForContext={userCanEditFilesForContext}
                userCanDeleteFilesForContext={userCanDeleteFilesForContext}
                userCanRestrictFilesForContext={userCanRestrictFilesForContext}
                usageRightsRequiredForContext={usageRightsRequiredForContext}
                onSortChange={sort.set}
                sort={sort}
                searchString={search.term}
                selectedRows={selectedRows}
                setSelectedRows={setSelectedRows}
                handleFileDropRef={handleFileDropRef}
                selectAllRef={selectAllRef}
              />
            }
            usageBar={userCanManageFilesForContext && <FilesUsageBar />}
            pagination={
              <>
                <Alert
                  liveRegion={() => document.getElementById('flash_screenreader_holder')!}
                  liveRegionPoliteness="polite"
                  screenReaderOnly
                  data-testid="pagination-announcement"
                >
                  {paginationAlert}
                </Alert>
                {!isLoading && page.total > 1 && (
                  <Pagination
                    as="nav"
                    labelNext={I18n.t('Next page')}
                    labelPrev={I18n.t('Previous page')}
                    variant="compact"
                    currentPage={page.current}
                    totalPageNumber={page.total}
                    onPageChange={page.set}
                    data-testid="files-pagination"
                  />
                )}
              </>
            }
          />
        </RowsProvider>
      </RowFocusProvider>
    </FileManagementProvider>
  )
}

const ResponsiveFilesApp = () => {
  const isUserContext = getFilesEnv().showingAllContexts
  const {data: folders, error} = useGetFolders()

  useEffect(() => {
    if (error instanceof UnauthorizedError) {
      window.location.href = '/login'
    }
  }, [error])

  const isNotFoundError = error instanceof NotFoundError
  if (isNotFoundError) {
    return <NotFoundArtwork />
  }

  if (!folders) {
    return null
  }

  return (
    <Responsive
      match="media"
      query={{
        small: {maxWidth: canvas.breakpoints.small},
        medium: {maxWidth: '1140px'},
      }}
      render={(_props: any, matches: string[] | undefined) => (
        <FilesApp
          isUserContext={isUserContext}
          folders={folders}
          size={(matches?.[0] as 'small' | 'medium') || 'large'}
        />
      )}
    />
  )
}

export default ResponsiveFilesApp

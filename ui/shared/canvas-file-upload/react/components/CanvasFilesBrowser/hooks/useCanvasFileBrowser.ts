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

import {useState, useEffect} from 'react'
import axios from '@canvas/axios'
import parseLinkHeader from 'link-header-parsing/parseLinkHeader'
import {CanvasFolder, CanvasFile} from '../../../types'
import {
  formatFolderData,
  updateFoldersWithNewFolders,
  updateFoldersWithNewFiles,
} from '../utils/folderHelpers'

const FILE_TYPE = 'files'
const FOLDER_TYPE = 'folders'

interface UseCanvasFileBrowserProps {
  courseID: string
}

export const useCanvasFileBrowser = ({courseID}: UseCanvasFileBrowserProps) => {
  const [loadedFolders, setLoadedFolders] = useState<Record<string, CanvasFolder>>({})
  const [loadedFiles, setLoadedFiles] = useState<Record<string, CanvasFile>>({})
  const [error, setError] = useState<Error | null>(null)
  const [pendingAPIRequests, setPendingAPIRequests] = useState(0)
  const [selectedFolderID, setSelectedFolderID] = useState<string | null>(null)
  const [loadedContent, setLoadedContent] = useState<
    Record<string, {files: boolean; folders: boolean}>
  >({})

  useEffect(() => {
    loadCourseRootFolder()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [courseID])

  const folderContentApiUrl = (folderID: string, type: string) => {
    return `/api/v1/folders/${folderID}/${type}?include=user`
  }

  const folderContentsLoaded = (folderID: string, type: string) => {
    const content = loadedContent[folderID]
    if (!content) return false
    return type === FILE_TYPE ? content.files : content.folders
  }

  const handleUpdateSelectedFolder = (folderID: string) => {
    // Load files and folders for the selected folder
    if (!folderContentsLoaded(folderID, FILE_TYPE)) {
      loadFolderContents(folderID, FILE_TYPE)
    }
    if (!folderContentsLoaded(folderID, FOLDER_TYPE)) {
      loadFolderContents(folderID, FOLDER_TYPE)
    }
    setSelectedFolderID(folderID)

    // Focus management
    setTimeout(() => {
      const newFocus =
        document.getElementById('parent-folder') ||
        document.getElementById(`folder-${loadedFolders[folderID]?.subFolderIDs[0]}`)
      newFocus?.focus()
    }, 0)
  }

  const loadCourseRootFolder = async () => {
    if (!courseID) return

    try {
      setPendingAPIRequests(prev => prev + 1)
      const resp = await axios.get(`/api/v1/courses/${courseID}/folders/root`, {
        headers: {Accept: 'application/json+canvas-string-ids'},
      })
      const rootFolder = resp.data

      // Format and store the course root folder
      const formattedFolder = formatFolderData(rootFolder)
      setLoadedFolders({[formattedFolder.id]: formattedFolder})
      setSelectedFolderID(formattedFolder.id)

      // Load files and subfolders for the root folder
      loadFolderContents(formattedFolder.id, FILE_TYPE)
      loadFolderContents(formattedFolder.id, FOLDER_TYPE)
    } catch (err) {
      setError(err as Error)
    } finally {
      setPendingAPIRequests(prev => prev - 1)
    }
  }

  const loadFolderContents = async (folderID: string, type: string, url?: string, opts?: any) => {
    try {
      setPendingAPIRequests(prev => prev + 1)
      const requestUrl = url || folderContentApiUrl(folderID, type)
      const resp = await axios.get(requestUrl, opts)
      const newItems = Array.isArray(resp.data) ? resp.data : [resp.data]

      // Apply custom folder name if provided
      if (opts?.folder_name) {
        newItems.forEach((item: any) => (item.name = opts.folder_name))
      }

      updateLoadedItems(type, newItems)

      // Mark this content type as loaded for this folder
      setLoadedContent(prev => ({
        ...prev,
        [folderID]: {
          files: type === FILE_TYPE ? true : prev[folderID]?.files || false,
          folders: type === FOLDER_TYPE ? true : prev[folderID]?.folders || false,
        },
      }))

      const linkHeader = parseLinkHeader(resp.headers.link) as {next?: string}
      if (linkHeader?.next) {
        loadFolderContents(folderID, type, linkHeader.next, opts)
      }
    } catch (err) {
      setError(err as Error)
    } finally {
      setPendingAPIRequests(prev => prev - 1)
    }
  }

  const updateLoadedItems = (type: string, newItems: any[]) => {
    if (type === FILE_TYPE) {
      updateLoadedFiles(newItems)
    } else {
      updateLoadedFolders(newItems)
    }
  }

  const updateLoadedFolders = (newFolders: any[]) => {
    setLoadedFolders(prevState => {
      return updateFoldersWithNewFolders(prevState, newFolders)
    })
  }

  const updateLoadedFiles = (newFiles: CanvasFile[]) => {
    setLoadedFolders(prevFolders => {
      return updateFoldersWithNewFiles(prevFolders, newFiles)
    })

    setLoadedFiles(prevFiles => {
      const loadedFiles = JSON.parse(JSON.stringify(prevFiles))
      newFiles.forEach(file => {
        loadedFiles[file.id] = file
      })
      return loadedFiles
    })
  }

  return {
    loadedFolders,
    loadedFiles,
    error,
    isLoading: pendingAPIRequests > 0,
    selectedFolderID,
    handleUpdateSelectedFolder,
  }
}

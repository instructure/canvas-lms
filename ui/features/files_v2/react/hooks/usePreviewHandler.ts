/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {useLocation, useNavigate} from 'react-router-dom'
import {useGetFile} from './useGetFile'
import {File} from '../../interfaces/File'
import {get} from 'es-toolkit/compat'

interface UsePreviewHandlerProps {
  collection: File[]
  contextType?: string
  contextId?: string
}

interface PreviewState {
  isModalOpen: boolean
  previewFile: File | null
  isFileInCollection: boolean
  showNavigationButtons: boolean
  error: string | null
}

const createClosedState = (): PreviewState => ({
  isModalOpen: false,
  previewFile: null,
  isFileInCollection: false,
  showNavigationButtons: false,
  error: null,
})

const createOpenState = (
  collection: File[],
  previewFile: File | null,
  isFileInCollection: boolean,
  error: string | null = null,
): PreviewState => ({
  isModalOpen: true,
  previewFile,
  isFileInCollection,
  showNavigationButtons: isFileInCollection && collection.length > 1,
  error,
})

const determinePreviewState = (
  previewId: string | null,
  collection: File[],
  fetchedFile: File | undefined,
  fetchError: any,
  isFetchingFile: boolean,
): PreviewState => {
  if (!previewId) {
    return createClosedState()
  }

  const fileInCollection = collection.find(file => file.id.toString() === previewId)

  if (fileInCollection) {
    return createOpenState(collection, fileInCollection, true)
  }

  if (fetchedFile) {
    return createOpenState(collection, fetchedFile, false)
  }

  if ((fetchError || (!fetchedFile && !fileInCollection)) && !isFetchingFile) {
    return createOpenState(collection, null, false, 'File not found')
  }

  return createClosedState()
}

const getPreviewIdFromURL = (location: ReturnType<typeof useLocation>) => {
  const searchParams = new URLSearchParams(location.search)
  return searchParams.get('preview')
}

export const usePreviewHandler = ({collection, contextType, contextId}: UsePreviewHandlerProps) => {
  const location = useLocation()
  const navigate = useNavigate()
  const [previewState, setPreviewState] = useState<PreviewState>(createClosedState())
  const previewId = getPreviewIdFromURL(location)

  const {
    data: fetchedFile,
    isLoading: isFetchingFile,
    error: fetchError,
  } = useGetFile({
    fileId:
      previewId && !collection.some(file => file.id.toString() === previewId) ? previewId : null,
    contextType,
    contextId,
  })

  useEffect(() => {
    const newState = determinePreviewState(
      previewId,
      collection,
      fetchedFile,
      fetchError,
      isFetchingFile,
    )
    setPreviewState(newState)
  }, [previewId, collection, fetchedFile, fetchError, isFetchingFile])

  const handleCloseModal = () => {
    setPreviewState(prev => ({...prev, isModalOpen: false}))
    const searchParams = new URLSearchParams(location.search)
    searchParams.delete('preview')
    const newSearch = searchParams.toString()
    navigate(newSearch ? `?${newSearch}` : location.pathname, {replace: true})
  }

  const handleOpenPreview = (file: File) => {
    const searchParams = new URLSearchParams(location.search)
    searchParams.set('preview', file.id.toString())
    navigate(`?${searchParams.toString()}`, {replace: true})
  }

  return {
    previewState,
    previewHandlers: {
      handleCloseModal,
      handleOpenPreview,
    },
    isFetchingFile,
  }
}

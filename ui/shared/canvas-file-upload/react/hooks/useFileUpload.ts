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

import {useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {uploadFile} from '@canvas/upload-file'
import axios from '@canvas/axios'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {ContextFile} from '../types'

const I18n = createI18nScope('canvas_file_upload')

interface UseFileUploadOptions {
  files: ContextFile[]
  onFilesChange: (files: ContextFile[]) => void
  courseId: string
  allowedFileTypes?: string[]
  maxFileSizeMB?: number
  maxFiles?: number
}

interface UseFileUploadReturn {
  uploadingFileNames: Set<string>
  handleDrop: (
    acceptedFiles: ArrayLike<DataTransferItem | File>,
    rejectedFiles: ArrayLike<DataTransferItem | File>,
  ) => Promise<void>
  isUploading: boolean
}

export const useFileUpload = ({
  files,
  onFilesChange,
  courseId,
  allowedFileTypes,
  maxFileSizeMB,
  maxFiles,
}: UseFileUploadOptions): UseFileUploadReturn => {
  const [uploadingFileNames, setUploadingFileNames] = useState<Set<string>>(new Set())

  const handleDrop = async (
    acceptedFiles: ArrayLike<DataTransferItem | File>,
    _rejectedFiles: ArrayLike<DataTransferItem | File>,
  ) => {
    try {
      // Filter out files that exceed size limit (if specified) or are duplicates
      const validFiles: File[] = []
      const oversizedFiles: string[] = []

      Array.from(acceptedFiles).forEach(file => {
        if (file instanceof File) {
          // Check if file already exists in the list (silently skip duplicates)
          const isDuplicate = files.some(existingFile => existingFile.display_name === file.name)

          if (isDuplicate) {
            // Skip duplicate file without notification
          } else if (maxFileSizeMB && file.size > maxFileSizeMB * 1024 * 1024) {
            oversizedFiles.push(file.name)
          } else {
            validFiles.push(file)
          }
        }
      })

      // Show error for oversized files
      if (oversizedFiles.length > 0) {
        showFlashAlert({
          message: I18n.t(
            {
              one: 'File "%{files}" exceeds the %{maxSize}MB size limit and was not uploaded.',
              other: 'Files "%{files}" exceed the %{maxSize}MB size limit and were not uploaded.',
            },
            {
              count: oversizedFiles.length,
              files: oversizedFiles.join('", "'),
              maxSize: maxFileSizeMB,
            },
          ),
          type: 'error',
        })
      }

      // If no valid files remain, stop here
      if (validFiles.length === 0) {
        return
      }

      // Check if adding these files would exceed the max file limit
      if (maxFiles && files.length + validFiles.length > maxFiles) {
        const allowedCount = maxFiles - files.length
        if (allowedCount <= 0) {
          showFlashAlert({
            message: I18n.t(
              'You have reached the maximum of %{maxFiles} files. Please remove some files before adding more.',
              {maxFiles},
            ),
            type: 'error',
          })
          return
        } else {
          showFlashAlert({
            message: I18n.t(
              'Only %{allowedCount} of %{totalCount} files were uploaded to stay within the %{maxFiles} file limit.',
              {allowedCount, totalCount: validFiles.length, maxFiles},
            ),
            type: 'warning',
          })
          validFiles.splice(allowedCount) // Keep only the allowed number of files
        }
      }

      const uploadUrl = `/api/v1/courses/${courseId}/files`

      // Add files to uploading state
      setUploadingFileNames(prev => {
        const newSet = new Set(prev)
        validFiles.forEach(file => newSet.add(file.name))
        return newSet
      })

      // Track uploaded files in this batch
      const uploadedInBatch: ContextFile[] = []

      // Upload all valid files
      const uploadPromises = validFiles.map(async file => {
        try {
          // Upload file to Canvas
          const attachment = await uploadFile(
            uploadUrl,
            {
              name: file.name,
              content_type: file.type,
            },
            file,
            axios,
          )

          const uploadedFile = attachment as ContextFile

          // Add to batch and update files list immediately
          uploadedInBatch.push(uploadedFile)
          onFilesChange([...files, ...uploadedInBatch])

          // Remove from uploading state
          setUploadingFileNames(prev => {
            const newSet = new Set(prev)
            newSet.delete(file.name)
            return newSet
          })

          return uploadedFile
        } catch (error: any) {
          // Remove from uploading state on error
          setUploadingFileNames(prev => {
            const newSet = new Set(prev)
            newSet.delete(file.name)
            return newSet
          })

          showFlashAlert({
            message: I18n.t('Failed to upload %{fileName}: %{error}', {
              fileName: file.name,
              error: error.message || 'Unknown error',
            }),
            type: 'error',
          })
          return null
        }
      })

      const uploadedFiles = (await Promise.all(uploadPromises)).filter(
        (file): file is ContextFile => file !== null,
      )

      if (uploadedFiles.length > 0) {
        showFlashAlert({
          message: I18n.t(
            {one: '1 file uploaded successfully', other: '%{count} files uploaded successfully'},
            {count: uploadedFiles.length},
          ),
          type: 'success',
        })
      }
    } catch (error: any) {
      showFlashAlert({
        message: I18n.t('Upload failed: %{error}', {error: error.message || 'Unknown error'}),
        type: 'error',
      })
    }
  }

  const isUploading = uploadingFileNames.size > 0

  return {
    uploadingFileNames,
    handleDrop,
    isUploading,
  }
}

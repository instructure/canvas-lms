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

import {useRef} from 'react'
import {saveClosedCaptions, saveClosedCaptionsForAttachment} from '../../saveMediaRecording'
import type {CaptionUploadConfig, Subtitle} from '../types'

interface UseClosedCaptionUploadProps {
  uploadConfig?: CaptionUploadConfig
  subtitles: Subtitle[]
  onUploadSuccess?: (subtitle: Subtitle) => void
  onUploadError?: (error: Error, locale: string) => void
  onDeleteSuccess?: (locale: string) => void
  onDeleteError?: (error: Error, locale: string) => void
}

/**
 * Hook for uploading and deleting caption files using batch APIs
 * Sends the full list of subtitles on each operation
 */
export function useClosedCaptionUpload(props: UseClosedCaptionUploadProps) {
  const {uploadConfig, subtitles, onUploadSuccess, onUploadError, onDeleteSuccess, onDeleteError} =
    props

  const mediaObjectId = uploadConfig?.mediaObjectId
  const attachmentId = uploadConfig?.attachmentId
  const origin = uploadConfig?.origin
  const headers = uploadConfig?.headers
  const maxBytes = uploadConfig?.maxBytes
  const subtitlesRef = useRef(subtitles)
  subtitlesRef.current = subtitles

  const uploadCaption = async (locale: string, file: File) => {
    try {
      const rcsConfig = {origin, headers, method: 'PUT'}

      // Build subtitle list for batch API:
      // - Existing captions: {locale} (no file, no isNew)
      // - New caption: {locale, file, isNew: true}
      const subtitleList = [
        ...subtitlesRef.current.filter(s => s.locale !== locale).map(s => ({locale: s.locale})),
        {locale, file, isNew: true as const},
      ]

      if (mediaObjectId) {
        await saveClosedCaptions(mediaObjectId, subtitleList, rcsConfig, maxBytes)
      } else if (attachmentId) {
        await saveClosedCaptionsForAttachment(attachmentId, subtitleList, rcsConfig, maxBytes)
      } else {
        throw new Error('Either mediaObjectId or attachmentId must be provided')
      }

      // Return subtitle info for state update
      onUploadSuccess?.({
        locale,
        file: {name: file.name},
        isNew: false,
      })
    } catch (error) {
      onUploadError?.(error as Error, locale)
    }
  }

  const deleteCaption = async (locale: string) => {
    try {
      const rcsConfig = {origin, headers, method: 'PUT'}

      // Build subtitle list without the deleted caption
      const subtitleList = subtitlesRef.current
        .filter(s => s.locale !== locale)
        .map(s => ({locale: s.locale}))

      if (mediaObjectId) {
        await saveClosedCaptions(mediaObjectId, subtitleList, rcsConfig, maxBytes)
      } else if (attachmentId) {
        await saveClosedCaptionsForAttachment(attachmentId, subtitleList, rcsConfig, maxBytes)
      } else {
        throw new Error('Either mediaObjectId or attachmentId must be provided')
      }

      onDeleteSuccess?.(locale)
    } catch (error) {
      onDeleteError?.(error as Error, locale)
    }
  }

  return {
    uploadCaption,
    deleteCaption,
  }
}

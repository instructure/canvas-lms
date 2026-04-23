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

import {useCallback, useEffect, useRef, useState} from 'react'
import formatMessage from '../../format-message'
import type {CaptionCreationMode, LanguageOption, Subtitle} from '../types'

interface UseClosedCaptionStateParams {
  initialSubtitles?: Subtitle[]
  /** Will be used later to propagate subtitle changes to parents */
  onUpdateSubtitles: (subtitles: Subtitle[]) => void
  closedCaptionLanguages: LanguageOption[]
}

interface UseClosedCaptionStateReturn {
  subtitles: Subtitle[]
  creationMode: CaptionCreationMode | null
  announcement: string | null
  setAnnouncement: React.Dispatch<React.SetStateAction<string | null>>
  handleNewButtonClick: () => void
  handleCreationModeSelect: (mode: CaptionCreationMode) => void
  handleCancelCreation: () => void
  handleDeleteRow: (locale: string) => void
  handleCaptionProcessing: (params: {locale: string; file?: File; isAsr?: boolean}) => void
  handleCaptionUploaded: (subtitle: Subtitle) => void
  handleCaptionUploadFailed: (locale: string, failedOperation: 'upload' | 'delete' | 'asr') => void
  handleCaptionRetrying: (locale: string) => void
}

/**
 * Manages state for closed captions panel
 * Handles add/delete logic and screen reader announcements
 */
export function useClosedCaptionState({
  initialSubtitles = [],
  onUpdateSubtitles,
  closedCaptionLanguages,
}: UseClosedCaptionStateParams): UseClosedCaptionStateReturn {
  const [subtitles, setSubtitles] = useState<Subtitle[]>(initialSubtitles)
  const [creationMode, setCreationMode] = useState<CaptionCreationMode | null>(null)
  const [announcement, setAnnouncement] = useState<string | null>(null)

  // Always-current ref so async callbacks (e.g. inside .catch()) read the
  // latest subtitle list even after re-renders that changed state.
  const subtitlesRef = useRef(subtitles)
  subtitlesRef.current = subtitles

  // Sync internal state when parent passes updated subtitles.
  useEffect(() => {
    setSubtitles(initialSubtitles)
  }, [initialSubtitles])

  const handleNewButtonClick = useCallback(() => {
    setAnnouncement(null)
  }, [])

  const handleCreationModeSelect = useCallback((mode: CaptionCreationMode) => {
    setCreationMode(mode)
  }, [])

  const handleCancelCreation = useCallback(() => {
    setCreationMode(null)
  }, [])

  const handleDeleteRow = useCallback(
    (locale: string) => {
      const deletedLanguage = closedCaptionLanguages.find(l => l.id === locale)
      const newSubtitles = subtitlesRef.current.filter(s => s.locale !== locale)
      setSubtitles(newSubtitles)
      onUpdateSubtitles(newSubtitles)
      setAnnouncement(
        formatMessage(`Captions have been deleted for {lang}`, {
          lang: deletedLanguage?.label || locale,
        }),
      )
    },
    [closedCaptionLanguages, onUpdateSubtitles],
  )

  // Called when file is selected and upload starts
  // (handleLanguageSelected + handleFileSelected already add to list with isNew=true)
  // Just need to mark as processing
  const handleCaptionProcessing = useCallback(
    ({locale, file, isAsr}: {locale: string; file?: File; isAsr?: boolean}) => {
      const updatedSubtitles: Subtitle[] = [
        ...subtitlesRef.current,
        {
          locale,
          ...(file && {file: {name: file.name}, rawFile: file}),
          workflow_state: 'processing' as const,
          ...(isAsr && {asr: true}),
        },
      ]
      setSubtitles(updatedSubtitles)
      onUpdateSubtitles(updatedSubtitles)
      setCreationMode(null)
    },
    [onUpdateSubtitles],
  )

  // Called when upload succeeds
  const handleCaptionUploaded = useCallback(
    (subtitle: Subtitle) => {
      const language = closedCaptionLanguages.find(l => l.id === subtitle.locale)
      const updatedSubtitles = subtitlesRef.current.map(s =>
        s.locale === subtitle.locale ? {...subtitle, workflow_state: 'ready' as const} : s,
      )
      setSubtitles(updatedSubtitles)
      onUpdateSubtitles(updatedSubtitles)
      setAnnouncement(
        formatMessage(`Captions have been added for {lang}`, {
          lang: language?.label || subtitle.locale,
        }),
      )
      handleCancelCreation()
    },
    [closedCaptionLanguages, onUpdateSubtitles, handleCancelCreation],
  )

  // Called when upload or delete fails
  const handleCaptionUploadFailed = useCallback(
    (locale: string, failedOperation: 'upload' | 'delete' | 'asr') => {
      const language = closedCaptionLanguages.find(l => l.id === locale)
      const captionName = language?.label || locale

      const failedMessages = {
        upload: {
          display: formatMessage('Upload Failed'),
          announcement: formatMessage('{captionName} caption upload failed', {captionName}),
        },
        delete: {
          display: formatMessage('Delete Failed'),
          announcement: formatMessage('{captionName} caption delete failed', {captionName}),
        },
        asr: {
          display: formatMessage('Caption generation failed'),
          announcement: formatMessage('{captionName} caption generation failed', {captionName}),
        },
      }

      const {display: displayMessage, announcement: announcementMessage} =
        failedMessages[failedOperation]

      const updatedSubtitles = subtitlesRef.current.map(s =>
        s.locale === locale
          ? {
              ...s,
              workflow_state: 'failed' as const,
              errorMessage: displayMessage,
              failedOperation,
            }
          : s,
      )
      setSubtitles(updatedSubtitles)
      onUpdateSubtitles(updatedSubtitles)
      setAnnouncement(announcementMessage)
      handleCancelCreation()
    },
    [closedCaptionLanguages, handleCancelCreation, onUpdateSubtitles],
  )

  // Called when retry is triggered for a failed caption.
  const handleCaptionRetrying = useCallback(
    (locale: string) => {
      const updatedSubtitles = subtitlesRef.current.map(s =>
        s.locale === locale
          ? {
              ...s,
              workflow_state: 'processing' as const,
              errorMessage: undefined,
              failedOperation: undefined,
            }
          : s,
      )
      setSubtitles(updatedSubtitles)
      onUpdateSubtitles(updatedSubtitles)
    },
    [onUpdateSubtitles],
  )

  return {
    subtitles,
    creationMode,
    announcement,
    setAnnouncement,
    handleNewButtonClick,
    handleCreationModeSelect,
    handleCancelCreation,
    handleDeleteRow,
    handleCaptionProcessing,
    handleCaptionUploaded,
    handleCaptionUploadFailed,
    handleCaptionRetrying,
  }
}

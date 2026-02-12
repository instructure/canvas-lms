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

import {useCallback, useEffect, useState} from 'react'
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
  handleNewButtonClick: () => void
  handleCreationModeSelect: (mode: CaptionCreationMode) => void
  handleCancelCreation: () => void
  handleDeleteRow: (locale: string) => void
  handleCaptionProcessing: (locale: string, file: File) => void
  handleCaptionUploaded: (subtitle: Subtitle) => void
  handleCaptionUploadFailed: (locale: string, errorMessage: string) => void
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

  // Sync internal state when parent passes updated subtitles
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

      setSubtitles(prev => {
        const newSubtitles = prev.filter(s => s.locale !== locale)
        onUpdateSubtitles(newSubtitles)
        return newSubtitles
      })

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
    (locale: string, file: File) => {
      setSubtitles(prev => {
        const updatedSubtitles: Subtitle[] = [
          ...prev,
          {
            locale,
            file: {name: file.name},
            status: 'processing' as const,
          },
        ]
        onUpdateSubtitles(updatedSubtitles)
        return updatedSubtitles
      })

      setCreationMode(null)
    },
    [onUpdateSubtitles],
  )

  // Called when upload succeeds
  const handleCaptionUploaded = useCallback(
    (subtitle: Subtitle) => {
      const language = closedCaptionLanguages.find(l => l.id === subtitle.locale)

      setSubtitles(prev => {
        const updatedSubtitles = prev.map(s =>
          s.locale === subtitle.locale ? {...subtitle, status: 'uploaded' as const} : s,
        )
        onUpdateSubtitles(updatedSubtitles)
        return updatedSubtitles
      })

      setAnnouncement(
        formatMessage(`Captions have been added for {lang}`, {
          lang: language?.label || subtitle.locale,
        }),
      )

      handleCancelCreation()
    },
    [closedCaptionLanguages, onUpdateSubtitles, handleCancelCreation],
  )

  // Called when upload fails
  const handleCaptionUploadFailed = useCallback(
    (locale: string, errorMessage: string) => {
      const language = closedCaptionLanguages.find(l => l.id === locale)
      const announcedErrorMessage = formatMessage(errorMessage, {
        captionName: language?.label || locale,
      })

      setSubtitles(prev => {
        const updatedSubtitles = prev.map(s =>
          s.locale === locale
            ? {...s, status: 'failed' as const, errorMessage: formatMessage('Failed')}
            : s,
        )
        onUpdateSubtitles(updatedSubtitles)
        return updatedSubtitles
      })

      setAnnouncement(announcedErrorMessage)

      handleCancelCreation()
    },
    [closedCaptionLanguages, handleCancelCreation, onUpdateSubtitles],
  )

  return {
    subtitles,
    creationMode,
    announcement,
    handleNewButtonClick,
    handleCreationModeSelect,
    handleCancelCreation,
    handleDeleteRow,
    handleCaptionProcessing,
    handleCaptionUploaded,
    handleCaptionUploadFailed,
  }
}

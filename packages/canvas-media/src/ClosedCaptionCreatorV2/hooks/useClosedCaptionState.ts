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

import {useCallback, useState} from 'react'
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
  handleAddSubtitle: (locale: string, file: File, languageLabel: string) => void
  handleDeleteRow: (locale: string) => void
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

  const handleNewButtonClick = useCallback(() => {
    setAnnouncement(null)
  }, [])

  const handleCreationModeSelect = useCallback((mode: CaptionCreationMode) => {
    setCreationMode(mode)
  }, [])

  const handleCancelCreation = useCallback(() => {
    setCreationMode(null)
  }, [])

  const handleAddSubtitle = useCallback(
    (locale: string, file: File, languageLabel: string) => {
      // Add subtitle with isNew=true (loading state)
      const newSubtitles: Subtitle[] = [
        ...subtitles,
        {
          locale,
          file: {name: file.name},
          isNew: true,
        },
      ]
      setSubtitles(newSubtitles)
      onUpdateSubtitles(newSubtitles)
      setCreationMode(null)
      setAnnouncement(
        formatMessage(`Captions have been added for {lang}`, {
          lang: languageLabel,
        }),
      )

      setTimeout(() => {
        // After a delay, set isNew to false to indicate upload complete
        // This is a totally mocked of working will be cleaned up when real upload is implemented
        const updatedSubtitles = newSubtitles.map(subtitle =>
          subtitle.locale === locale ? {...subtitle, isNew: false} : subtitle,
        )
        setSubtitles(updatedSubtitles)
        onUpdateSubtitles(updatedSubtitles)
      }, 1500)
    },
    [subtitles, onUpdateSubtitles],
  )

  const handleDeleteRow = useCallback(
    (locale: string) => {
      const deletedLanguage = closedCaptionLanguages.find(l => l.id === locale)
      const newSubtitles = subtitles.filter(s => s.locale !== locale)

      setSubtitles(newSubtitles)
      onUpdateSubtitles(newSubtitles)
      setAnnouncement(
        formatMessage(`Captions have been deleted for {lang}`, {
          lang: deletedLanguage?.label || locale,
        }),
      )
    },
    [subtitles, closedCaptionLanguages, onUpdateSubtitles],
  )

  return {
    subtitles,
    creationMode,
    announcement,
    handleNewButtonClick,
    handleCreationModeSelect,
    handleCancelCreation,
    handleAddSubtitle,
    handleDeleteRow,
  }
}

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

import {Alert} from '@instructure/ui-alerts'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {useMemo} from 'react'
import {sortedClosedCaptionLanguageList} from '../closedCaptionLanguages'
import {AutoCaptioning} from './AutoCaptioning'
import {CaptionCreationModePicker} from './CaptionCreationModePicker'
import {CaptionRow} from './CaptionRow'
import {useClosedCaptionState} from './hooks/useClosedCaptionState'
import {useLanguageFiltering} from './hooks/useLanguageFiltering'
import {ManualCaptionCreator} from './ManualCaptionCreator'
import type {CaptionUploadConfig, Subtitle} from './types'
import {useClosedCaptionUpload} from './hooks/useClosedCaptionUpload'

/**
 * Props for ClosedCaptionPanel component
 */
export interface ClosedCaptionPanelProps {
  liveRegion: () => HTMLElement | null
  mountNode?: HTMLElement | (() => HTMLElement | null)
  subtitles?: Subtitle[]
  onUpdateSubtitles: (subtitles: Subtitle[]) => void
  userLocale?: string
  uploadConfig?: CaptionUploadConfig
  onCaptionUploaded?: (subtitle: Subtitle) => void
  onCaptionDeleted?: (locale: string) => void
}

export function ClosedCaptionPanelV2({
  liveRegion,
  mountNode,
  subtitles: initialSubtitles = [],
  onUpdateSubtitles,
  userLocale = 'en',
  uploadConfig,
  onCaptionUploaded,
  onCaptionDeleted,
}: ClosedCaptionPanelProps) {
  // Get sorted language list based on user locale
  const closedCaptionLanguages = useMemo(
    () => sortedClosedCaptionLanguageList(userLocale),
    [userLocale],
  )

  // State management
  const state = useClosedCaptionState({
    initialSubtitles,
    onUpdateSubtitles,
    closedCaptionLanguages,
  })

  // Filter available languages
  const {availableLanguages} = useLanguageFiltering({
    allLanguages: closedCaptionLanguages,
    subtitles: state.subtitles,
  })

  // Always use immediate upload hook (this component always uploads immediately)
  const upload = useClosedCaptionUpload({
    uploadConfig,
    subtitles: state.subtitles,
    onUploadSuccess: subtitle => {
      state.handleCaptionUploaded(subtitle)
      onCaptionUploaded?.(subtitle)
    },
    onUploadError: (_error, locale) => {
      state.handleCaptionUploadFailed(locale, '{captionName} caption upload failed')
    },
    onDeleteSuccess: locale => {
      state.handleDeleteRow(locale)
      onCaptionDeleted?.(locale)
    },
    onDeleteError: (_error, locale) => {
      state.handleCaptionUploadFailed(locale, '{captionName} caption delete failed')
    },
  })

  return (
    <Flex direction="column" gap="medium" data-testid="ClosedCaptionPanel" width="100%">
      {/* Screen reader announcement */}
      {state.announcement && (
        <Alert
          liveRegion={liveRegion}
          screenReaderOnly={true}
          isLiveRegionAtomic={true}
          liveRegionPoliteness="assertive"
        >
          {state.announcement}
        </Alert>
      )}

      {/* Existing captions */}
      {state.subtitles.length > 0 && (
        <View>
          {state.subtitles.map(subtitle => {
            const language = closedCaptionLanguages.find(l => l.id === subtitle.locale)
            // Use subtitle status directly (processing, failed, or uploaded)
            const status = subtitle.status || 'uploaded'

            return (
              <CaptionRow
                key={subtitle.locale}
                status={status}
                captionName={language?.label || ''}
                errorMessage={subtitle.errorMessage}
                liveRegion={liveRegion}
                isInherited={subtitle.inherited}
                onDelete={() => upload.deleteCaption(subtitle.locale)}
              />
            )
          })}
        </View>
      )}

      {state.creationMode === null && (
        <CaptionCreationModePicker onSelect={state.handleCreationModeSelect} />
      )}

      {state.creationMode === 'manual' && (
        <ManualCaptionCreator
          languages={availableLanguages}
          liveRegion={liveRegion}
          mountNode={mountNode}
          onCancel={state.handleCancelCreation}
          onPrimary={(languageId: string, file: File) => {
            // Find the language object
            const language = closedCaptionLanguages.find(l => l.id === languageId)
            if (language) {
              state.handleCaptionProcessing(languageId, file)
              upload.uploadCaption(languageId, file)
            }
          }}
        />
      )}

      {state.creationMode === 'auto' && (
        <AutoCaptioning handleCancel={state.handleCancelCreation} />
      )}
    </Flex>
  )
}

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
import {List} from '@instructure/ui-list'
import formatMessage from 'format-message'
import {useMemo} from 'react'
import {sortedAsrLanguageList} from '../asrClosedCaptionLanguages'
import {sortedClosedCaptionLanguageList} from '../closedCaptionLanguages'
import {trackPendoEvent} from '../utils/trackPendoEvent'
import {AutoCaptioning} from './AutoCaptioning'
import {CaptionCreationModePicker} from './CaptionCreationModePicker'
import {CaptionRow} from './CaptionRow'
import {doAsrRequest} from './hooks/doAsrRequest'
import {useClosedCaptionState} from './hooks/useClosedCaptionState'
import {useClosedCaptionUpload} from './hooks/useClosedCaptionUpload'
import {useLanguageFiltering} from './hooks/useLanguageFiltering'
import {ManualCaptionCreator} from './ManualCaptionCreator'
import type {CaptionUploadConfig, LanguageOption, Subtitle} from './types'

function getCaptionName(subtitle: Subtitle, language: LanguageOption | undefined): string {
  return subtitle.asr
    ? formatMessage('{languageLabel} (Automatic)', {languageLabel: language?.label})
    : (language?.label ?? '')
}

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
  onDirtyStateChanged?: (isDirty: boolean) => void
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
  onDirtyStateChanged,
}: ClosedCaptionPanelProps) {
  // Get sorted language lists based on user locale
  const closedCaptionLanguages = useMemo(
    () => sortedClosedCaptionLanguageList(userLocale),
    [userLocale],
  )

  const asrLanguages = useMemo(() => sortedAsrLanguageList(userLocale), [userLocale])

  // State management
  const state = useClosedCaptionState({
    initialSubtitles,
    onUpdateSubtitles,
    closedCaptionLanguages,
  })

  // Filter available languages for manual upload (all caption languages)
  const {availableLanguages: availableManualLanguages} = useLanguageFiltering({
    allLanguages: closedCaptionLanguages,
    subtitles: state.subtitles,
  })

  // Filter available languages for auto-captioning (ASR-only languages)
  const {availableLanguages: availableAsrLanguages} = useLanguageFiltering({
    allLanguages: asrLanguages,
    subtitles: state.subtitles,
  })

  // Always use immediate upload hook (this component always uploads immediately)
  const upload = useClosedCaptionUpload({
    uploadConfig,
    subtitles: state.subtitles,
    onUploadSuccess: subtitle => {
      trackPendoEvent('canvas_caption_result', {
        flow_type: 'upload_file',
        result: 'success',
        language: subtitle.locale,
      })
      state.handleCaptionUploaded(subtitle)
      onCaptionUploaded?.(subtitle)
    },
    onUploadError: (_error, locale) => {
      trackPendoEvent('canvas_caption_result', {flow_type: 'upload_file', result: 'failed'})
      state.handleCaptionUploadFailed(locale, 'upload')
    },
    onDeleteSuccess: locale => {
      state.handleDeleteRow(locale)
      onCaptionDeleted?.(locale)
    },
    onDeleteError: (_error, locale) => {
      trackPendoEvent('canvas_caption_validation_error', {
        flow_type: 'upload_file',
        error_type: 'delete_failed',
      })
      state.handleCaptionUploadFailed(locale, 'delete')
    },
  })

  function getRetryHandler(subtitle: Subtitle): (() => void) | undefined {
    const {locale, failedOperation, rawFile} = subtitle

    let retryAction

    if (failedOperation === 'delete') {
      retryAction = () => upload.deleteCaption(locale)
    } else if (failedOperation === 'upload' && rawFile) {
      retryAction = () => upload.uploadCaption(locale, rawFile)
    } else if (failedOperation === 'asr') {
      retryAction = () => {
        doAsrRequest(uploadConfig, locale).catch(() => {
          state.handleCaptionUploadFailed(locale, 'asr')
        })
      }
    }

    if (!retryAction) return undefined

    return () => {
      trackPendoEvent('canvas_caption_retry_clicked', {
        flow_type: failedOperation === 'upload' ? 'upload_file' : 'request_auto',
      })
      state.handleCaptionRetrying(locale)
      retryAction()
    }
  }

  // Check if an auto-captioned subtitle already exists
  const hasAutoCaptionAlready = state.subtitles.some(subtitle => subtitle.asr === true)

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
        <List isUnstyled aria-label={formatMessage('Captions')} margin="0">
          {state.subtitles.map(subtitle => {
            const language = closedCaptionLanguages.find(l => l.id === subtitle.locale)
            const deleteHandler = () => {
              trackPendoEvent('canvas_caption_item_action', {
                action: 'delete',
                caption_source: subtitle.asr ? 'automatic' : 'uploaded',
                language: subtitle.locale,
              })
              upload.deleteCaption(subtitle.locale)
            }
            // Client-side failures (failedOperation is set) get retry only.
            // Server-side failures (no failedOperation) get delete only.
            const showDelete = subtitle.workflow_state !== 'failed' || !subtitle.failedOperation
            return (
              <List.Item key={subtitle.locale}>
                <CaptionRow
                  url={subtitle.url}
                  filename={subtitle.filename}
                  workflow_state={subtitle.workflow_state ?? 'ready'}
                  captionName={getCaptionName(subtitle, language)}
                  errorMessage={subtitle.errorMessage}
                  onRetry={getRetryHandler(subtitle)}
                  isInherited={subtitle.inherited}
                  onDelete={showDelete ? deleteHandler : undefined}
                />
              </List.Item>
            )
          })}
        </List>
      )}

      {state.creationMode === null && (
        <CaptionCreationModePicker
          onSelect={state.handleCreationModeSelect}
          showAutoOption={!hasAutoCaptionAlready}
        />
      )}

      {state.creationMode === 'manual' && (
        <ManualCaptionCreator
          languages={availableManualLanguages}
          liveRegion={liveRegion}
          mountNode={mountNode}
          onCancel={() => {
            state.handleCancelCreation()
            onDirtyStateChanged?.(false)
          }}
          onPrimary={(languageId: string, file: File) => {
            const language = closedCaptionLanguages.find(l => l.id === languageId)
            if (language) {
              trackPendoEvent('canvas_caption_submitted', {
                flow_type: 'upload_file',
                language: languageId,
              })
              state.handleCaptionProcessing({locale: languageId, file})
              upload.uploadCaption(languageId, file)
            }
            onDirtyStateChanged?.(false)
          }}
          onDirtyStateChanged={onDirtyStateChanged}
        />
      )}

      {state.creationMode === 'auto' && (
        <AutoCaptioning
          onCancel={() => {
            state.handleCancelCreation()
            onDirtyStateChanged?.(false)
          }}
          liveRegion={liveRegion}
          mountNode={mountNode}
          languages={availableAsrLanguages}
          onPrimary={(languageId: string) => {
            const language = asrLanguages.find(l => l.id === languageId)
            if (language) {
              trackPendoEvent('canvas_caption_submitted', {
                flow_type: 'request_auto',
                language: languageId,
              })
              state.handleCaptionProcessing({locale: languageId, isAsr: true})
              doAsrRequest(uploadConfig, languageId).catch(() => {
                trackPendoEvent('canvas_caption_result', {
                  flow_type: 'request_auto',
                  result: 'failed',
                  language: languageId,
                })
                state.handleCaptionUploadFailed(languageId, 'asr')
              })
            }
            onDirtyStateChanged?.(false)
          }}
          onDirtyStateChanged={onDirtyStateChanged}
        />
      )}
    </Flex>
  )
}

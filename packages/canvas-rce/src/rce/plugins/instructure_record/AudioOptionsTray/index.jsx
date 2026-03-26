/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {
  ClosedCaptionPanel,
  ClosedCaptionPanelV2,
  CONSTANTS,
  trackPendoEvent,
} from '@instructure/canvas-media'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Checkbox, CheckboxGroup} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {Heading} from '@instructure/ui-heading'
import {IconExternalLinkLine} from '@instructure/ui-icons'
import {Link} from '@instructure/ui-link'
import {Spinner} from '@instructure/ui-spinner'
import {Tooltip} from '@instructure/ui-tooltip'
import {Tray} from '@instructure/ui-tray'
import {arrayOf, bool, func, shape, string} from 'prop-types'
import React, {useEffect, useRef, useState} from 'react'
import Bridge from '../../../../bridge'
import formatMessage from '../../../../format-message'
import RCEGlobals from '../../../../rce/RCEGlobals'
import RceApiSource, {originFromHost} from '../../../../rcs/api'
import {instuiPopupMountNodeFn} from '../../../../util/fullscreenHelpers'
import {StoreProvider} from '../../shared/StoreContext'
import {getTrayHeight} from '../../shared/trayUtils'
import {mapViewerRestrictions, readViewerRestrictions} from '../utils'

const getLiveRegion = () => document.getElementById('flash_screenreader_holder')

export default function AudioOptionsTray({
  open,
  onEntered,
  onExited,
  onDismiss,
  onSave,
  trayProps,
  audioOptions,
  requestSubtitlesFromIframe,
  onCaptionsModified,
  isLoading = false,
}) {
  const [subtitles, setSubtitles] = useState(audioOptions.tracks || [])
  const api = new RceApiSource(trayProps)
  const [hasUnsavedChanges, setHasUnsavedChanges] = useState(false)
  const fetchedFromIframeRef = useRef(false)

  const [viewerRestrictions, setViewerRestrictions] = useState(() =>
    readViewerRestrictions(audioOptions.viewerRestrictions),
  )

  useEffect(() => {
    if (!isLoading && subtitles.length === 0 && !fetchedFromIframeRef.current) {
      // only request subtitle data after mount
      fetchedFromIframeRef.current = true
      requestSubtitlesFromIframe(setSubtitles)
    }
  }, [isLoading, subtitles.length, requestSubtitlesFromIframe])

  const isAsrCaptioningImprovements = RCEGlobals.getFeatures()?.rce_asr_captioning_improvements

  useEffect(() => {
    if (open && isAsrCaptioningImprovements) {
      trackPendoEvent('canvas_media_options_opened', {
        entry_point: 'quick_menu',
        media_kind: 'audio',
      })
    }
  }, [open, isAsrCaptioningImprovements])

  const handleUpdateSubtitles = newSubtitles => {
    setSubtitles(newSubtitles)
  }

  const handleSave = (_e, contentProps) => {
    onSave({
      media_object_id: audioOptions.id,
      subtitles,
      attachment_id: audioOptions.attachmentId,
      updateMediaObject: contentProps.updateMediaObject,
      viewerRestrictions: mapViewerRestrictions(viewerRestrictions),
    })
  }

  const handleDirtyCheck = isDirty => {
    setHasUnsavedChanges(isDirty)
  }

  return (
    <StoreProvider {...trayProps}>
      {contentProps => (
        <Tray
          key="audio-options-tray"
          data-mce-component={true}
          label={formatMessage('Audio Options Tray')}
          mountNode={instuiPopupMountNodeFn}
          onDismiss={onDismiss}
          onEntered={onEntered}
          onExited={onExited}
          open={open}
          placement="end"
          shouldCloseOnDocumentClick={true}
          shouldContainFocus={true}
          shouldReturnFocus={true}
          size={isAsrCaptioningImprovements ? 'regular' : 'small'}
        >
          <Flex direction="column" height={getTrayHeight()}>
            <Flex.Item as="header" padding="medium">
              <Flex direction="row">
                <Flex.Item shouldGrow={true} shouldShrink={true}>
                  <Heading as="h2">{formatMessage('Audio Options')}</Heading>
                </Flex.Item>
                <Flex.Item>
                  <CloseButton
                    placement="static"
                    color="primary"
                    onClick={onDismiss}
                    screenReaderLabel={formatMessage('Close')}
                  />
                </Flex.Item>
              </Flex>
            </Flex.Item>
            {isLoading ? (
              <Flex.Item textAlign="center" margin="xx-large" padding="xx-large">
                <Spinner renderTitle={formatMessage('Loading')} />
              </Flex.Item>
            ) : (
              <Flex.Item as="form" shouldGrow={true} margin="none" shouldShrink={true}>
                <Flex justifyItems="space-between" direction="column" height="100%">
                  <Flex.Item shouldGrow={true} padding="small" shouldShrink={true}>
                    <Flex direction="column">
                      {isAsrCaptioningImprovements && (
                        <Flex.Item padding="small">
                          <CheckboxGroup
                            name="viewer-restrictions"
                            onChange={setViewerRestrictions}
                            defaultValue={viewerRestrictions}
                            description={
                              <Heading level="h4" as="h3">
                                {formatMessage('Viewer Restrictions')}
                              </Heading>
                            }
                          >
                            <Checkbox
                              variant="toggle"
                              label={formatMessage('Show Rolling Transcript')}
                              value="show_rolling_transcript"
                            />
                          </CheckboxGroup>
                        </Flex.Item>
                      )}
                      <Flex.Item padding="small">
                        <FormFieldGroup
                          description={
                            <Heading level="h4" as="h3">
                              {formatMessage('Closed Captions/Subtitles')}
                            </Heading>
                          }
                        >
                          {!isAsrCaptioningImprovements ? (
                            <ClosedCaptionPanel
                              key={subtitles.reduce((acc, track) => acc + track.locale, '')}
                              subtitles={subtitles.map(st => ({
                                locale: st.locale,
                                file: {name: st.language || st.locale},
                                asr: Boolean(st.asr),
                              }))}
                              uploadMediaTranslations={Bridge.uploadMediaTranslations}
                              languages={Bridge.languages}
                              updateSubtitles={newSubtitles => setSubtitles(newSubtitles)}
                              liveRegion={getLiveRegion}
                            />
                          ) : (
                            <ClosedCaptionPanelV2
                              subtitles={subtitles.map(st => ({
                                ...st,
                                file: {name: st.language || st.locale},
                                asr: Boolean(st.asr),
                              }))}
                              languages={Bridge.languages}
                              userLocale={Bridge.userLocale}
                              onUpdateSubtitles={handleUpdateSubtitles}
                              liveRegion={getLiveRegion}
                              mountNode={instuiPopupMountNodeFn}
                              uploadConfig={{
                                mediaObjectId: audioOptions.id,
                                attachmentId: audioOptions.attachmentId,
                                origin: originFromHost(api.host),
                                headers: api.jwt ? {Authorization: `Bearer ${api.jwt}`} : undefined,
                                maxBytes: CONSTANTS.CC_FILE_MAX_BYTES,
                              }}
                              onCaptionUploaded={subtitle => {
                                // Update local state so "Done" button knows about it
                                setSubtitles(prev => [
                                  ...prev.filter(s => s.locale !== subtitle.locale),
                                  subtitle,
                                ])
                                onCaptionsModified?.()
                              }}
                              onCaptionDeleted={locale => {
                                setSubtitles(prev => prev.filter(s => s.locale !== locale))
                                onCaptionsModified?.()
                              }}
                              onDirtyStateChanged={handleDirtyCheck}
                            />
                          )}
                        </FormFieldGroup>
                      </Flex.Item>
                      {isAsrCaptioningImprovements ? (
                        <Flex.Item padding="small">
                          <Link
                            id="tray-transcript-help-link"
                            variant="standalone"
                            renderIcon={<IconExternalLinkLine />}
                            href="https://productmarketing.instructuremedia.com/embed/32388c5a-580c-40f0-85a2-6b4042ddcccb"
                            target="_blank"
                            rel="noopener noreferrer"
                          >
                            {formatMessage('How to request and edit captions?')}
                          </Link>
                        </Flex.Item>
                      ) : null}
                    </Flex>
                  </Flex.Item>
                  <Flex.Item
                    background="secondary"
                    borderWidth="small none none none"
                    padding="small medium"
                    textAlign="end"
                  >
                    <Tooltip
                      renderTip={formatMessage('Unsaved changes will be lost.')}
                      placement="top"
                      on={['hover', 'focus']}
                      preventTooltip={!hasUnsavedChanges}
                      mountNode={instuiPopupMountNodeFn}
                    >
                      <Button onClick={e => handleSave(e, contentProps)} color="primary">
                        {formatMessage('Done')}
                      </Button>
                    </Tooltip>
                  </Flex.Item>
                </Flex>
              </Flex.Item>
            )}
          </Flex>
        </Tray>
      )}
    </StoreProvider>
  )
}

AudioOptionsTray.propTypes = {
  onEntered: func,
  onExited: func,
  onDismiss: func,
  onSave: func,
  open: bool.isRequired,
  requestSubtitlesFromIframe: func,
  trayProps: shape({
    host: string.isRequired,
    jwt: string.isRequired,
  }).isRequired,
  audioOptions: shape({
    id: string.isRequired,
    titleText: string.isRequired,
    tracks: arrayOf(
      shape({
        locale: string.isRequired,
      }),
    ),
    viewerRestrictions: shape({
      show_rolling_transcript: bool,
    }),
  }).isRequired,
  onCaptionsModified: func,
  isLoading: bool,
}

AudioOptionsTray.defaultProps = {
  onEntered: null,
  onExited: null,
  onDismiss: null,
  onSave: null,
  requestSubtitlesFromIframe: () => {},
  onCaptionsModified: null,
}

/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import {Tooltip} from '@instructure/ui-tooltip'
import {Tray} from '@instructure/ui-tray'
import {View} from '@instructure/ui-view'
import {arrayOf, bool, func, number, shape, string} from 'prop-types'
import React, {useCallback, useEffect, useRef, useState} from 'react'
import Bridge from '../../../../bridge'
import formatMessage from '../../../../format-message'
import RCEGlobals from '../../../../rce/RCEGlobals'
import RceApiSource, {originFromHost} from '../../../../rcs/api'
import {instuiPopupMountNodeFn} from '../../../../util/fullscreenHelpers'
import {
  CUSTOM,
  labelForImageSize,
  MIN_HEIGHT_STUDIO_PLAYER,
  MIN_PERCENTAGE,
  MIN_WIDTH_STUDIO_PLAYER,
  MIN_WIDTH_VIDEO,
  scaleToSize,
  scaleVideoSize,
  studioPlayerSizes,
  videoSizes,
} from '../../instructure_image/ImageEmbedOptions'
import DimensionsInput, {useDimensionsState} from '../../shared/DimensionsInput'
import {StoreProvider} from '../../shared/StoreContext'
import {parsedStudioOptionsPropType} from '../../shared/StudioLtiSupportUtils'
import {getTrayHeight} from '../../shared/trayUtils'
import {
  getPlayerLayoutSizes,
  labelForPlayerLayoutSize,
  playerLayoutDimensions,
  SMALL,
  scalePlayerLayoutForHeight,
  scalePlayerLayoutForWidth,
} from '../playerLayoutOptions'
import {mapStudioEmbedOptions, mapViewerRestrictions, readViewerRestrictions} from '../utils'

const getLiveRegion = () => document.getElementById('flash_screenreader_holder')

export default function VideoOptionsTray({
  videoOptions,
  onRequestClose,
  onSave,
  open,
  trayProps,
  requestSubtitlesFromIframe = () => {},
  onEntered = null,
  onExited = null,
  id = 'video-options-tray',
  studioOptions = null,
  forBlockEditorUse = false,
  onStudioEmbedOptionChanged = () => {},
  onCaptionsModified = null,
  isLoading = false,
}) {
  const isConsolidatedMediaPlayer = RCEGlobals.getFeatures()?.consolidated_media_player
  const isEmbedImprovements = RCEGlobals.getFeatures()?.rce_studio_embed_improvements
  const isAsrCaptioningImprovements = RCEGlobals.getFeatures()?.rce_asr_captioning_improvements
  const {naturalHeight, naturalWidth} = videoOptions
  const currentHeight = videoOptions.appliedHeight || naturalHeight
  const currentWidth = videoOptions.appliedWidth || naturalWidth
  const [titleText, setTitleText] = useState(videoOptions.titleText)
  const [displayAs, setDisplayAs] = useState('embed')
  const [videoSize, setVideoSize] = useState(() => {
    if (isAsrCaptioningImprovements) {
      const match = Object.entries(playerLayoutDimensions).find(
        ([, dims]) => dims.width === videoOptions.appliedWidth,
      )
      if (match) return match[0]
    }
    return videoOptions.videoSize
  })
  const [videoHeight, setVideoHeight] = useState(currentHeight)
  const [videoWidth, setVideoWidth] = useState(currentWidth)
  const [subtitles, setSubtitles] = useState(videoOptions.tracks || [])
  const [minWidth] = useState(() => {
    if (isAsrCaptioningImprovements) {
      return playerLayoutDimensions[SMALL].width
    }
    return isConsolidatedMediaPlayer ? MIN_WIDTH_STUDIO_PLAYER : MIN_WIDTH_VIDEO
  })
  const [minHeight] = useState(() => {
    if (isAsrCaptioningImprovements) {
      return playerLayoutDimensions[SMALL].height
    }
    return isConsolidatedMediaPlayer
      ? MIN_HEIGHT_STUDIO_PLAYER
      : Math.round((videoHeight / videoWidth) * MIN_WIDTH_VIDEO)
  })
  const [minPercentage] = useState(MIN_PERCENTAGE)
  const [editLocked, setEditLocked] = useState(null)
  const [loading, setLoading] = useState(true)

  const [viewerRestrictions, setViewerRestrictions] = useState(() =>
    readViewerRestrictions(videoOptions.viewerRestrictions),
  )
  const [studioEmbedOptions, setStudioEmbedOptions] = useState(() =>
    mapStudioEmbedOptions(studioOptions?.embedOptions),
  )
  const [hasUnsavedChanges, setHasUnsavedChanges] = useState(false)
  const fetchedFromIframeRef = useRef(false)

  const titleInputRef = useRef(null)

  const isStudio = !!studioOptions
  const showDisplayOptions = (!isStudio || studioOptions.convertibleToLink) && !forBlockEditorUse
  const showSizeControls = (!isStudio || studioOptions.resizable) && !forBlockEditorUse
  const dimensionsState = useDimensionsState(
    videoOptions,
    {minHeight, minWidth, minPercentage},
    isAsrCaptioningImprovements
      ? {scaleFns: {width: scalePlayerLayoutForWidth, height: scalePlayerLayoutForHeight}}
      : {},
  )
  const api = new RceApiSource(trayProps)
  const videoSizeOptions = isConsolidatedMediaPlayer
    ? isAsrCaptioningImprovements
      ? getPlayerLayoutSizes()
      : studioPlayerSizes
    : videoSizes

  useEffect(() => {
    if (videoOptions.attachmentId) {
      api
        .getFile(videoOptions.attachmentId, {include: ['blueprint_course_status']})
        .then(response => {
          setEditLocked(
            response?.restricted_by_master_course && response?.is_master_course_child_content,
          )
          setLoading(false)
        })
        .catch(_error => {
          setLoading(false)
        })
    }
  }, [videoOptions.attachmentId])

  useEffect(() => {
    if (!isLoading && subtitles.length === 0 && !fetchedFromIframeRef.current) {
      // only request subtitle data after mount
      fetchedFromIframeRef.current = true
      requestSubtitlesFromIframe(setSubtitles)
    }
  }, [isLoading, subtitles.length, requestSubtitlesFromIframe])

  useEffect(() => {
    if (open && isAsrCaptioningImprovements) {
      trackPendoEvent('canvas_media_options_opened', {
        entry_point: 'quick_menu',
        media_kind: 'video',
      })
    }
  }, [open, isAsrCaptioningImprovements])

  function handleTitleTextChange(event) {
    setTitleText(event.target.value)
  }

  function handleDisplayAsChange(event) {
    event.target.focus()
    setDisplayAs(event.target.value)
  }

  function handleVideoSizeChange(_event, selectedOption) {
    setVideoSize(selectedOption.value)
    if (selectedOption.value === CUSTOM) {
      setVideoHeight(currentHeight)
      setVideoWidth(currentWidth)
    } else if (isAsrCaptioningImprovements) {
      const {width, height} = playerLayoutDimensions[selectedOption.value]
      setVideoHeight(height)
      setVideoWidth(width)
    } else {
      const {height, width} = isConsolidatedMediaPlayer
        ? scaleVideoSize(selectedOption.value, naturalWidth, naturalHeight)
        : scaleToSize(selectedOption.value, naturalWidth, naturalHeight)

      setVideoHeight(height)
      setVideoWidth(width)
    }
  }

  function handleUpdateSubtitles(new_subtitles) {
    setSubtitles(new_subtitles)
  }

  const handleEmbedOptionChange = useCallback(
    options => {
      const mappedOptions = options.reduce((a, c) => {
        a[c] = options.includes(c)
        return a
      }, {})
      setStudioEmbedOptions(options)
      onStudioEmbedOptionChanged(mappedOptions)
    },
    [onStudioEmbedOptionChanged],
  )

  function handleSave(event, updateMediaObject) {
    event.preventDefault()
    if (titleText.trim() === '') {
      if (titleInputRef.current) {
        titleInputRef.current.focus()
      }
      return
    }
    let appliedHeight = videoHeight
    let appliedWidth = videoWidth
    if (videoSize === CUSTOM) {
      appliedHeight = dimensionsState.height
      appliedWidth = dimensionsState.width
    }
    if (isAsrCaptioningImprovements) {
      trackPendoEvent('canvas_player_layout_selected', {
        layout_type: videoSize.replace('-', '_'),
      })
    }
    onSave({
      media_object_id: videoOptions.id,
      attachment_id: videoOptions.attachmentId,
      titleText,
      appliedHeight,
      appliedWidth,
      displayAs,
      subtitles,
      updateMediaObject,
      editLocked,
      viewerRestrictions: mapViewerRestrictions(viewerRestrictions),
    })
  }

  const handleDirtyCheck = isDirty => {
    setHasUnsavedChanges(isDirty)
  }

  const messagesForSize = []
  if (videoSize !== CUSTOM && !isAsrCaptioningImprovements) {
    messagesForSize.push({
      text: formatMessage('{width} x {height}px', {height: videoHeight, width: videoWidth}),
      type: 'hint',
    })
  }
  const saveDisabled = displayAs === 'embed' && videoSize === CUSTOM && !dimensionsState.isValid

  return (
    <StoreProvider {...trayProps}>
      {contentProps => (
        <Tray
          key="video-options-tray"
          data-mce-component={true}
          label={
            isStudio
              ? formatMessage('Studio Media Options Tray')
              : formatMessage('Video Options Tray')
          }
          mountNode={instuiPopupMountNodeFn}
          onDismiss={onRequestClose}
          onEntered={onEntered}
          onExited={onExited}
          open={open}
          placement="end"
          shouldCloseOnDocumentClick={true}
          shouldContainFocus={true}
          shouldReturnFocus={true}
          size="regular"
        >
          <Flex direction="column" height={getTrayHeight()}>
            <Flex.Item as="header" padding="medium">
              <Flex direction="row">
                <Flex.Item shouldGrow={true} shouldShrink={true}>
                  <Heading as="h2">
                    {isStudio
                      ? formatMessage('Studio Media Options')
                      : formatMessage('Video Options')}
                  </Heading>
                </Flex.Item>
                <Flex.Item>
                  <CloseButton
                    color="primary"
                    onClick={onRequestClose}
                    screenReaderLabel={formatMessage('Close')}
                  />
                </Flex.Item>
              </Flex>
            </Flex.Item>
            {(loading && videoOptions.attachmentId) || isLoading ? (
              <Flex.Item textAlign="center" margin="xx-large" padding="xx-large">
                <Spinner renderTitle={formatMessage('Loading')} />
              </Flex.Item>
            ) : (
              <Flex.Item as="form" shouldGrow={true} margin="none" shouldShrink={true}>
                <Flex justifyItems="space-between" direction="column" height="100%">
                  <Flex.Item shouldGrow={true} padding="small" shouldShrink={true}>
                    <Flex direction="column">
                      {!editLocked && (
                        <Flex.Item padding="small">
                          {isStudio ? (
                            <Flex direction="column">
                              <Flex.Item>
                                <Text weight="bold">{formatMessage('Media Title')}</Text>
                              </Flex.Item>
                              <Flex.Item padding="small none none small">{titleText}</Flex.Item>
                            </Flex>
                          ) : (
                            <TextInput
                              interaction={displayAs === 'link' ? 'disabled' : 'enabled'}
                              renderLabel={formatMessage('Title')}
                              onChange={handleTitleTextChange}
                              placeholder={formatMessage('Enter a media title')}
                              value={titleText}
                              inputRef={el => (titleInputRef.current = el)}
                              messages={
                                titleText?.trim() === ''
                                  ? [
                                      {
                                        text: formatMessage("Title can't be blank"),
                                        type: 'newError',
                                      },
                                    ]
                                  : []
                              }
                              isRequired
                            />
                          )}
                        </Flex.Item>
                      )}
                      {showDisplayOptions && (
                        <Flex.Item margin="small none none none" padding="small">
                          <RadioInputGroup
                            description={formatMessage('Display Options')}
                            name="display-video-as"
                            onChange={handleDisplayAsChange}
                            value={displayAs}
                          >
                            <RadioInput label={formatMessage('Embed Video')} value="embed" />
                            <RadioInput
                              label={formatMessage('Display Text Link (Opens in a new tab)')}
                              value="link"
                            />
                          </RadioInputGroup>
                        </Flex.Item>
                      )}
                      {showSizeControls && (
                        <Flex.Item margin="small none xx-small none">
                          <View as="div" padding="small small xx-small small">
                            <SimpleSelect
                              id={`${id}-size`}
                              mountNode={instuiPopupMountNodeFn}
                              disabled={displayAs !== 'embed'}
                              renderLabel={
                                isAsrCaptioningImprovements
                                  ? formatMessage('Player layout')
                                  : formatMessage('Size')
                              }
                              messages={messagesForSize}
                              assistiveText={formatMessage('Use arrow keys to navigate options.')}
                              onChange={handleVideoSizeChange}
                              value={videoSize}
                            >
                              {videoSizeOptions.map(size => (
                                <SimpleSelect.Option
                                  id={`${id}-size-${size}`}
                                  key={size}
                                  value={size}
                                >
                                  {isAsrCaptioningImprovements
                                    ? labelForPlayerLayoutSize(size)
                                    : labelForImageSize(size)}
                                </SimpleSelect.Option>
                              ))}
                            </SimpleSelect>
                            {isAsrCaptioningImprovements && !isStudio && (
                              <View as="div" margin="xx-small none none none">
                                <Text size="small">
                                  {formatMessage(
                                    'Transcript panel is available at widths above 720px.',
                                  )}
                                </Text>
                              </View>
                            )}
                          </View>
                          {videoSize === CUSTOM && (
                            <View as="div" padding="xx-small small">
                              <DimensionsInput
                                dimensionsState={dimensionsState}
                                disabled={displayAs !== 'embed'}
                                minHeight={minHeight}
                                minWidth={minWidth}
                                minPercentage={minPercentage}
                                hidePercentage={true}
                              />
                            </View>
                          )}
                        </Flex.Item>
                      )}
                      {isAsrCaptioningImprovements && !isStudio && (
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
                      {!isStudio && !editLocked && (
                        <Flex.Item padding="small">
                          <FormFieldGroup
                            description={
                              <Heading level="h4" as="h3">
                                {isAsrCaptioningImprovements
                                  ? formatMessage('Caption Manager')
                                  : formatMessage('Closed Captions/Subtitles')}
                              </Heading>
                            }
                          >
                            {!isAsrCaptioningImprovements && (
                              <ClosedCaptionPanel
                                key={subtitles.reduce((acc, track) => acc + track.locale, '')}
                                subtitles={subtitles.map(st => ({
                                  locale: st.locale,
                                  inherited: st.inherited,
                                  file: {name: st.language || st.locale}, // this is an artifact of ClosedCaptionCreatorRow's inards
                                }))}
                                uploadMediaTranslations={Bridge.uploadMediaTranslations}
                                userLocale={Bridge.userLocale}
                                updateSubtitles={handleUpdateSubtitles}
                                liveRegion={getLiveRegion}
                                mountNode={instuiPopupMountNodeFn}
                              />
                            )}
                            {isAsrCaptioningImprovements && (
                              <ClosedCaptionPanelV2
                                subtitles={subtitles.map(st => ({
                                  ...st,
                                  file: {name: st.language || st.locale},
                                  asr: Boolean(st.asr),
                                }))}
                                uploadMediaTranslations={Bridge.uploadMediaTranslations}
                                userLocale={Bridge.userLocale}
                                onUpdateSubtitles={handleUpdateSubtitles}
                                liveRegion={getLiveRegion}
                                mountNode={instuiPopupMountNodeFn}
                                uploadConfig={{
                                  mediaObjectId: videoOptions.id,
                                  attachmentId: videoOptions.attachmentId,
                                  origin: originFromHost(api.host),
                                  headers: api.jwt
                                    ? {Authorization: `Bearer ${api.jwt}`}
                                    : undefined,
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
                      )}
                      {isStudio && isEmbedImprovements ? (
                        <Flex.Item padding="small">
                          <CheckboxGroup
                            name="studio-embed-options"
                            onChange={handleEmbedOptionChange}
                            value={studioEmbedOptions}
                            description={
                              <Heading level="h4" as="h3">
                                {formatMessage('Viewer Restrictions')}
                              </Heading>
                            }
                          >
                            <Text variant="contentSmall">
                              {formatMessage('Changes will apply after you save this page.')}
                            </Text>
                            <Checkbox
                              label={formatMessage('Lock speed at 1x')}
                              value="lockSpeed"
                              variant="toggle"
                            />
                            {!studioOptions?.embedOptions?.isExternal ? (
                              <Checkbox
                                label={formatMessage('Allow media download')}
                                value="enableMediaDownload"
                                variant="toggle"
                              />
                            ) : null}
                            <Checkbox
                              label={formatMessage('Allow transcript download')}
                              value="enableTranscriptDownload"
                              variant="toggle"
                            />
                            <Checkbox
                              label={formatMessage('Show rolling transcript')}
                              value="showRollingTranscript"
                              variant="toggle"
                            />
                          </CheckboxGroup>
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
                      <Button
                        interaction={saveDisabled ? 'disabled' : 'enabled'}
                        onClick={event => handleSave(event, contentProps.updateMediaObject)}
                        color="primary"
                      >
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

VideoOptionsTray.propTypes = {
  videoOptions: shape({
    titleText: string,
    appliedHeight: number,
    appliedWidth: number,
    naturalHeight: number.isRequired,
    naturalWidth: number.isRequired,
    tracks: arrayOf(
      shape({
        locale: string.isRequired,
        inherited: bool,
      }),
    ),
    viewerRestrictions: shape({
      show_rolling_transcript: bool,
    }),
  }).isRequired,
  onEntered: func,
  onExited: func,
  onRequestClose: func.isRequired,
  onSave: func.isRequired,
  open: bool.isRequired,
  trayProps: shape({
    host: string.isRequired,
    jwt: string.isRequired,
  }),
  id: string,
  studioOptions: parsedStudioOptionsPropType,
  requestSubtitlesFromIframe: func,
  onStudioEmbedOptionChanged: func,
  onCaptionsModified: func,
  isLoading: bool,
}

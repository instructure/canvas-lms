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
import React, {useState, useEffect} from 'react'
import {arrayOf, bool, func, number, shape, string} from 'prop-types'
import {Button, CloseButton, IconButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {TextArea} from '@instructure/ui-text-area'
import {Text} from '@instructure/ui-text'
import {IconQuestionLine} from '@instructure/ui-icons'
import {Flex} from '@instructure/ui-flex'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'
import {Tooltip} from '@instructure/ui-tooltip'
import {Tray} from '@instructure/ui-tray'
import {StoreProvider} from '../../shared/StoreContext'
import {ClosedCaptionPanel} from '@instructure/canvas-media'
import {
  CUSTOM,
  MIN_WIDTH_VIDEO,
  MIN_PERCENTAGE,
  videoSizes,
  labelForImageSize,
  scaleToSize,
} from '../../instructure_image/ImageEmbedOptions'
import Bridge from '../../../../bridge'
import RceApiSource from '../../../../rcs/api'
import formatMessage from '../../../../format-message'
import DimensionsInput, {useDimensionsState} from '../../shared/DimensionsInput'
import {getTrayHeight} from '../../shared/trayUtils'
import {instuiPopupMountNode} from '../../../../util/fullscreenHelpers'
import {parsedStudioOptionsPropType} from '../../shared/StudioLtiSupportUtils'

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
}) {
  const {naturalHeight, naturalWidth} = videoOptions
  const currentHeight = videoOptions.appliedHeight || naturalHeight
  const currentWidth = videoOptions.appliedWidth || naturalWidth
  const [titleText, setTitleText] = useState(videoOptions.titleText)
  const [displayAs, setDisplayAs] = useState('embed')
  const [videoSize, setVideoSize] = useState(videoOptions.videoSize)
  const [videoHeight, setVideoHeight] = useState(currentHeight)
  const [videoWidth, setVideoWidth] = useState(currentWidth)
  const [subtitles, setSubtitles] = useState(videoOptions.tracks || [])
  const [minWidth] = useState(MIN_WIDTH_VIDEO)
  const [minHeight] = useState(Math.round((videoHeight / videoWidth) * MIN_WIDTH_VIDEO))
  const [minPercentage] = useState(MIN_PERCENTAGE)
  const [editLocked, setEditLocked] = useState(null)
  const [loading, setLoading] = useState(true)

  const isStudio = !!studioOptions
  const showDisplayOptions = !isStudio || studioOptions.convertibleToLink
  const showSizeControls = !isStudio || studioOptions.resizable

  const dimensionsState = useDimensionsState(videoOptions, {minHeight, minWidth, minPercentage})
  const api = new RceApiSource(trayProps)

  useEffect(() => {
    if(videoOptions.attachmentId) {
      api.getFile(videoOptions.attachmentId, {include: ['blueprint_course_status']})
        .then((response) => {
          setEditLocked(response?.restricted_by_master_course && response?.is_master_course_child_content)
          setLoading(false)
        })
        .catch((error) => {
          setLoading(false)
        })
    }
  }, [videoOptions.attachmentId])

  useEffect(() => {
    if (subtitles.length === 0) requestSubtitlesFromIframe(setSubtitles)
  }, [])

  function handleTitleTextChange(event) {
    setTitleText(event.target.value)
  }

  function handleDisplayAsChange(event) {
    event.target.focus()
    setDisplayAs(event.target.value)
  }

  function handleVideoSizeChange(event, selectedOption) {
    setVideoSize(selectedOption.value)
    if (selectedOption.value === CUSTOM) {
      setVideoHeight(currentHeight)
      setVideoWidth(currentWidth)
    } else {
      const {height, width} = scaleToSize(selectedOption.value, naturalWidth, naturalHeight)
      setVideoHeight(height)
      setVideoWidth(width)
    }
  }

  function handleUpdateSubtitles(new_subtitles) {
    setSubtitles(new_subtitles)
  }

  function handleSave(event, updateMediaObject) {
    event.preventDefault()
    let appliedHeight = videoHeight
    let appliedWidth = videoWidth
    if (videoSize === CUSTOM) {
      appliedHeight = dimensionsState.height
      appliedWidth = dimensionsState.width
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
    })
  }

  const tooltipText = formatMessage('Used by screen readers to describe the video')
  const textAreaLabel = (
    <Flex alignItems="center">
      <Flex.Item>{formatMessage('Title')}</Flex.Item>
      <Flex.Item margin="0 0 0 xx-small">
        <Tooltip
          on={['hover', 'focus']}
          placement="top"
          renderTip={
            <View display="block" id="alt-text-label-tooltip" maxWidth="14rem">
              {tooltipText}
            </View>
          }
        >
          <IconButton
            renderIcon={IconQuestionLine}
            size="small"
            screenReaderLabel={tooltipText}
            withBackground={false}
            withBorder={false}
          />
        </Tooltip>
      </Flex.Item>
    </Flex>
  )
  const messagesForSize = []
  if (videoSize !== CUSTOM) {
    messagesForSize.push({
      text: formatMessage('{width} x {height}px', {height: videoHeight, width: videoWidth}),
      type: 'hint',
    })
  }
  const saveDisabled =
    displayAs === 'embed' &&
    (titleText === '' || (videoSize === CUSTOM && !dimensionsState.isValid))

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
          mountNode={instuiPopupMountNode}
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
            {loading && videoOptions.attachmentId ? (
              <Flex.Item textAlign="center" margin="xx-large" padding="xx-large">
                <Spinner renderTitle={formatMessage("Loading")} />
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
                            <TextArea
                              aria-describedby="alt-text-label-tooltip"
                              disabled={displayAs === 'link'}
                              height="4rem"
                              label={textAreaLabel}
                              onChange={handleTitleTextChange}
                              placeholder={formatMessage('(Describe the video)')}
                              resize="vertical"
                              value={titleText}
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
                              mountNode={instuiPopupMountNode}
                              disabled={displayAs !== 'embed'}
                              renderLabel={formatMessage('Size')}
                              messages={messagesForSize}
                              assistiveText={formatMessage('Use arrow keys to navigate options.')}
                              onChange={handleVideoSizeChange}
                              value={videoSize}
                            >
                              {videoSizes.map(size => (
                                <SimpleSelect.Option
                                  id={`${id}-size-${size}`}
                                  key={size}
                                  value={size}
                                >
                                  {labelForImageSize(size)}
                                </SimpleSelect.Option>
                              ))}
                            </SimpleSelect>
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
                      {!isStudio && !editLocked && (
                        <Flex.Item padding="small">
                          <FormFieldGroup description={formatMessage('Closed Captions/Subtitles')}>
                            <ClosedCaptionPanel
                              subtitles={subtitles.map(st => ({
                                locale: st.locale,
                                inherited: st.inherited,
                                file: {name: st.language || st.locale}, // this is an artifact of ClosedCaptionCreatorRow's inards
                              }))}
                              uploadMediaTranslations={Bridge.uploadMediaTranslations}
                              userLocale={Bridge.userLocale}
                              updateSubtitles={handleUpdateSubtitles}
                              liveRegion={getLiveRegion}
                              mountNode={instuiPopupMountNode}
                            />
                          </FormFieldGroup>
                        </Flex.Item>
                      )}
                    </Flex>
                  </Flex.Item>
                  <Flex.Item
                    background="secondary"
                    borderWidth="small none none none"
                    padding="small medium"
                    textAlign="end"
                  >
                    <Button
                      disabled={saveDisabled}
                      onClick={event => handleSave(event, contentProps.updateMediaObject)}
                      color="primary"
                    >
                      {formatMessage('Done')}
                    </Button>
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
      })
    ),
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
  requestSubtitlesFromIframe: func
}

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
import React, {useState} from 'react'
import {arrayOf, bool, func, number, shape, string} from 'prop-types'
import {Button, CloseButton, IconButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {TextArea} from '@instructure/ui-text-area'
import {IconQuestionLine} from '@instructure/ui-icons'
import {Flex} from '@instructure/ui-flex'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {View} from '@instructure/ui-view'
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
import formatMessage from '../../../../format-message'
import DimensionsInput, {useDimensionsState} from '../../shared/DimensionsInput'
import {getTrayHeight} from '../../shared/trayUtils'

const getLiveRegion = () => document.getElementById('flash_screenreader_holder')
export default function VideoOptionsTray(props) {
  const {videoOptions, onEntered, onExited, onRequestClose, onSave, open, trayProps, id} = props
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

  const dimensionsState = useDimensionsState(videoOptions, {minHeight, minWidth, minPercentage})
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
      titleText,
      appliedHeight,
      appliedWidth,
      displayAs,
      subtitles,
      updateMediaObject,
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
          label={formatMessage('Video Options Tray')}
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
                  <Heading as="h2">{formatMessage('Video Options')}</Heading>
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
            <Flex.Item as="form" shouldGrow={true} margin="none" shouldShrink={true}>
              <Flex justifyItems="space-between" direction="column" height="100%">
                <Flex.Item shouldGrow={true} padding="small" shouldShrink={true}>
                  <Flex direction="column">
                    <Flex.Item padding="small">
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
                    </Flex.Item>
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
                    <Flex.Item margin="small none xx-small none">
                      <View as="div" padding="small small xx-small small">
                        <SimpleSelect
                          id={`${id}-size`}
                          disabled={displayAs !== 'embed'}
                          renderLabel={formatMessage('Size')}
                          messages={messagesForSize}
                          assistiveText={formatMessage('Use arrow keys to navigate options.')}
                          onChange={handleVideoSizeChange}
                          value={videoSize}
                        >
                          {videoSizes.map(size => (
                            <SimpleSelect.Option id={`${id}-size-${size}`} key={size} value={size}>
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
                          />
                        </View>
                      )}
                    </Flex.Item>
                    <Flex.Item padding="small">
                      <FormFieldGroup description={formatMessage('Closed Captions/Subtitles')}>
                        <ClosedCaptionPanel
                          subtitles={subtitles.map(st => ({
                            locale: st.locale,
                            file: {name: st.language || st.locale}, // this is an artifact of ClosedCaptionCreatorRow's inards
                          }))}
                          uploadMediaTranslations={Bridge.uploadMediaTranslations}
                          userLocale={Bridge.userLocale}
                          updateSubtitles={handleUpdateSubtitles}
                          liveRegion={getLiveRegion}
                        />
                      </FormFieldGroup>
                    </Flex.Item>
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
          </Flex>
        </Tray>
      )}
    </StoreProvider>
  )
}
VideoOptionsTray.propTypes = {
  videoOptions: shape({
    titleText: string.isRequired,
    appliedHeight: number,
    appliedWidth: number,
    naturalHeight: number.isRequired,
    naturalWidth: number.isRequired,
    tracks: arrayOf(shape({locale: string.isRequired})),
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
}
VideoOptionsTray.defaultProps = {
  onEntered: null,
  onExited: null,
  id: 'video-options-tray',
}

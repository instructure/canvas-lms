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
import {bool, func, number, shape, string} from 'prop-types'
import {ScreenReaderContent} from '@instructure/ui-a11y'
import {Button, CloseButton} from '@instructure/ui-buttons'

import {Heading} from '@instructure/ui-elements'
import {RadioInput, RadioInputGroup, Select, TextArea} from '@instructure/ui-forms'
import {IconQuestionLine} from '@instructure/ui-icons'
import {Flex, View} from '@instructure/ui-layout'
import {Tooltip, Tray} from '@instructure/ui-overlays'
import {StoreProvider} from '../../shared/StoreContext'

import {
  CUSTOM,
  MIN_HEIGHT,
  MIN_WIDTH,
  videoSizes,
  labelForImageSize,
  scaleToSize
} from '../../instructure_image/ImageEmbedOptions'
import formatMessage from '../../../../format-message'
import DimensionsInput, {useDimensionsState} from '../../shared/DimensionsInput'

export default function VideoOptionsTray(props) {
  const {videoOptions, onRequestClose, open} = props

  const {naturalHeight, naturalWidth} = videoOptions
  const currentHeight = videoOptions.appliedHeight || naturalHeight
  const currentWidth = videoOptions.appliedWidth || naturalWidth

  const [titleText, setTitleText] = useState(videoOptions.titleText)
  const [displayAs, setDisplayAs] = useState('embed')
  const [videoSize, setVideoSize] = useState(videoOptions.videoSize)
  const [videoHeight, setVideoHeight] = useState(currentHeight)
  const [videoWidth, setVideoWidth] = useState(currentWidth)

  const {trayProps} = props

  const dimensionsState = useDimensionsState(videoOptions, {
    minHeight: MIN_HEIGHT,
    minWidth: MIN_WIDTH
  })

  const videoSizeOption = {label: labelForImageSize(videoSize), value: videoSize}

  function handleTitleTextChange(event) {
    setTitleText(event.target.value)
  }

  function handleDisplayAsChange(event) {
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

  function handleSave(event, updateMediaObject) {
    event.preventDefault()

    let appliedHeight = videoHeight
    let appliedWidth = videoWidth
    if (videoSize === CUSTOM) {
      appliedHeight = dimensionsState.height
      appliedWidth = dimensionsState.width
    }

    props.onSave({
      media_object_id: props.videoOptions.id,
      titleText,
      appliedHeight,
      appliedWidth,
      displayAs,
      updateMediaObject
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
          tip={
            <View display="block" id="alt-text-label-tooltip" maxWidth="14rem">
              {tooltipText}
            </View>
          }
        >
          <Button icon={IconQuestionLine} size="small" variant="icon">
            <ScreenReaderContent>{tooltipText}</ScreenReaderContent>
          </Button>
        </Tooltip>
      </Flex.Item>
    </Flex>
  )

  const messagesForSize = []
  if (videoSize !== CUSTOM) {
    messagesForSize.push({
      text: formatMessage('{width} x {height}px', {height: videoHeight, width: videoWidth}),
      type: 'hint'
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
          data-mce-component
          label={formatMessage('Video Options Tray')}
          onDismiss={onRequestClose}
          onEntered={props.onEntered}
          onExited={props.onExited}
          open={open}
          placement="end"
          shouldCloseOnDocumentClick
          shouldContainFocus
          shouldReturnFocus
        >
          <Flex direction="column" height="100vh">
            <Flex.Item as="header" padding="medium">
              <Flex direction="row">
                <Flex.Item grow shrink>
                  <Heading as="h2">{formatMessage('Video Options')}</Heading>
                </Flex.Item>

                <Flex.Item>
                  <CloseButton placemet="static" variant="icon" onClick={onRequestClose}>
                    {formatMessage('Close')}
                  </CloseButton>
                </Flex.Item>
              </Flex>
            </Flex.Item>

            <Flex.Item as="form" grow margin="none" shrink>
              <Flex justifyItems="space-between" direction="column" height="100%">
                <Flex.Item grow padding="small" shrink>
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
                        <Select
                          disabled={displayAs !== 'embed'}
                          label={formatMessage('Size')}
                          messages={messagesForSize}
                          onChange={handleVideoSizeChange}
                          selectedOption={videoSizeOption}
                        >
                          {videoSizes.map(size => (
                            <option key={size} value={size}>
                              {labelForImageSize(size)}
                            </option>
                          ))}
                        </Select>
                      </View>

                      {videoSize === CUSTOM && (
                        <View as="div" padding="xx-small small">
                          <DimensionsInput
                            dimensionsState={dimensionsState}
                            disabled={displayAs !== 'embed'}
                            minHeight={MIN_HEIGHT}
                            minWidth={MIN_WIDTH}
                          />
                        </View>
                      )}
                    </Flex.Item>
                  </Flex>
                </Flex.Item>

                <Flex.Item
                  background="light"
                  borderWidth="small none none none"
                  padding="small medium"
                  textAlign="end"
                >
                  <Button
                    disabled={saveDisabled}
                    onClick={event => handleSave(event, contentProps.updateMediaObject)}
                    variant="primary"
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
    naturalWidth: number.isRequired
  }).isRequired,
  onEntered: func,
  onExited: func,
  onRequestClose: func.isRequired,
  onSave: func.isRequired,
  open: bool.isRequired,
  trayProps: shape({
    host: string.isRequired,
    jwt: string.isRequired
  })
}

VideoOptionsTray.defaultProps = {
  onEntered: null,
  onExited: null
}

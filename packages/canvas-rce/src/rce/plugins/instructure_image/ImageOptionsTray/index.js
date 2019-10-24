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
import {Checkbox, RadioInput, RadioInputGroup, Select, TextArea} from '@instructure/ui-forms'
import {IconQuestionLine} from '@instructure/ui-icons'
import {Flex, View} from '@instructure/ui-layout'
import {Tooltip, Tray} from '@instructure/ui-overlays'

import {
  CUSTOM,
  MIN_HEIGHT,
  MIN_WIDTH,
  imageSizes,
  labelForImageSize,
  scaleToSize
} from '../ImageEmbedOptions'
import formatMessage from '../../../../format-message'
import DimensionsInput, {useDimensionsState} from '../../shared/DimensionsInput'

export default function ImageOptionsTray(props) {
  const {imageOptions, onRequestClose, open} = props

  const {naturalHeight, naturalWidth} = imageOptions
  const currentHeight = imageOptions.appliedHeight || naturalHeight
  const currentWidth = imageOptions.appliedWidth || naturalWidth

  const [altText, setAltText] = useState(imageOptions.altText)
  const [isDecorativeImage, setIsDecorativeImage] = useState(imageOptions.isDecorativeImage)
  const [displayAs, setDisplayAs] = useState('embed')
  const [imageSize, setImageSize] = useState(imageOptions.imageSize)
  const [imageHeight, setImageHeight] = useState(currentHeight)
  const [imageWidth, setImageWidth] = useState(currentWidth)

  const dimensionsState = useDimensionsState(imageOptions, {
    minHeight: MIN_HEIGHT,
    minWidth: MIN_WIDTH
  })

  const imageSizeOption = {label: labelForImageSize(imageSize), value: imageSize}

  function handleAltTextChange(event) {
    setAltText(event.target.value)
  }

  function handleIsDecorativeChange(event) {
    setIsDecorativeImage(event.target.checked)
  }

  function handleDisplayAsChange(event) {
    setDisplayAs(event.target.value)
  }

  function handleImageSizeChange(event, selectedOption) {
    setImageSize(selectedOption.value)
    if (selectedOption.value === CUSTOM) {
      setImageHeight(currentHeight)
      setImageWidth(currentWidth)
    } else {
      const {height, width} = scaleToSize(selectedOption.value, naturalWidth, naturalHeight)
      setImageHeight(height)
      setImageWidth(width)
    }
  }

  function handleSave(event) {
    event.preventDefault()
    const savedAltText = isDecorativeImage ? '' : altText

    let appliedHeight = imageHeight
    let appliedWidth = imageWidth
    if (imageSize === CUSTOM) {
      appliedHeight = dimensionsState.height
      appliedWidth = dimensionsState.width
    }

    props.onSave({
      altText: savedAltText,
      appliedHeight,
      appliedWidth,
      displayAs,
      isDecorativeImage
    })
  }

  const tooltipText = formatMessage('Used by screen readers to describe the content of an image')
  const textAreaLabel = (
    <Flex alignItems="center">
      <Flex.Item>{formatMessage('Alt Text')}</Flex.Item>

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
  if (imageSize !== CUSTOM) {
    messagesForSize.push({
      text: formatMessage('{width} x {height}px', {height: imageHeight, width: imageWidth}),
      type: 'hint'
    })
  }

  const saveDisabled =
    displayAs === 'embed' &&
    ((!isDecorativeImage && altText === '') || (imageSize === CUSTOM && !dimensionsState.isValid))

  return (
    <Tray
      data-mce-component
      label={formatMessage('Image Options Tray')}
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
              <Heading as="h2">{formatMessage('Image Options')}</Heading>
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
                    disabled={isDecorativeImage || displayAs === 'link'}
                    height="4rem"
                    label={textAreaLabel}
                    onChange={handleAltTextChange}
                    placeholder={formatMessage('(Describe the image)')}
                    resize="vertical"
                    value={altText}
                  />
                </Flex.Item>

                <Flex.Item padding="small">
                  <Checkbox
                    checked={isDecorativeImage}
                    disabled={displayAs === 'link'}
                    label={formatMessage('No Alt Text (Decorative Image)')}
                    onChange={handleIsDecorativeChange}
                  />
                </Flex.Item>

                <Flex.Item margin="small none none none" padding="small">
                  <RadioInputGroup
                    description={formatMessage('Display Options')}
                    name="display-image-as"
                    onChange={handleDisplayAsChange}
                    value={displayAs}
                  >
                    <RadioInput label={formatMessage('Embed Image')} value="embed" />

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
                      onChange={handleImageSizeChange}
                      selectedOption={imageSizeOption}
                    >
                      {imageSizes.map(size => (
                        <option key={size} value={size}>
                          {labelForImageSize(size)}
                        </option>
                      ))}
                    </Select>
                  </View>

                  {imageSize === CUSTOM && (
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
              <Button disabled={saveDisabled} onClick={handleSave} variant="primary">
                {formatMessage('Done')}
              </Button>
            </Flex.Item>
          </Flex>
        </Flex.Item>
      </Flex>
    </Tray>
  )
}

ImageOptionsTray.propTypes = {
  imageOptions: shape({
    altText: string.isRequired,
    appliedHeight: number,
    appliedWidth: number,
    isDecorativeImage: bool.isRequired,
    naturalHeight: number.isRequired,
    naturalWidth: number.isRequired
  }).isRequired,
  onEntered: func,
  onExited: func,
  onRequestClose: func.isRequired,
  onSave: func.isRequired,
  open: bool.isRequired
}

ImageOptionsTray.defaultProps = {
  onEntered: null,
  onExited: null
}

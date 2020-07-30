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
import {CloseButton} from '@instructure/ui-buttons'

import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import {Tray} from '@instructure/ui-tray'

import {CUSTOM, MIN_HEIGHT, MIN_WIDTH, scaleToSize} from '../ImageEmbedOptions'
import formatMessage from '../../../../format-message'
import {useDimensionsState} from '../../shared/DimensionsInput'
import ImageOptionsForm from '../../shared/ImageOptionsForm'

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
    const savedAltText = isDecorativeImage ? altText || ' ' : altText

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

  const messagesForSize = []
  if (imageSize !== CUSTOM) {
    messagesForSize.push({
      text: formatMessage('{width} x {height}px', {height: imageHeight, width: imageWidth}),
      type: 'hint'
    })
  }

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
          <ImageOptionsForm
            imageSize={imageSize}
            displayAs={displayAs}
            isDecorativeImage={isDecorativeImage}
            altText={altText}
            dimensionsState={dimensionsState}
            handleAltTextChange={handleAltTextChange}
            handleIsDecorativeChange={handleIsDecorativeChange}
            handleDisplayAsChange={handleDisplayAsChange}
            handleImageSizeChange={handleImageSizeChange}
            messagesForSize={messagesForSize}
            handleSave={handleSave}
          />
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

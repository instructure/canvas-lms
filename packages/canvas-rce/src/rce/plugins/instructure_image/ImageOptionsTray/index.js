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
import {bool, func, number, shape, string} from 'prop-types'
import {Button, CloseButton} from '@instructure/ui-buttons'

import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import {Tray} from '@instructure/ui-tray'

import {CUSTOM, MIN_HEIGHT, MIN_WIDTH, scaleToSize} from '../ImageEmbedOptions'
import formatMessage from '../../../../format-message'
import {useDimensionsState} from '../../shared/DimensionsInput'
import ImageOptionsForm from '../../shared/ImageOptionsForm'
import {getTrayHeight, isExternalUrl} from '../../shared/trayUtils'
import validateURL from '../../instructure_links/validateURL'
import UrlPanel from '../../shared/Upload/UrlPanel'

export default function ImageOptionsTray(props) {
  const {imageOptions, onEntered, onExited, onRequestClose, onSave, open} = props

  const {naturalHeight, naturalWidth, isLinked} = imageOptions
  const currentHeight = imageOptions.appliedHeight || naturalHeight
  const currentWidth = imageOptions.appliedWidth || naturalWidth

  const [url, setUrl] = useState(imageOptions.url)
  const [showUrlField, setShowUrlField] = useState(false)
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

  function handleUrlChange(newUrl) {
    setUrl(newUrl)
  }

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

    onSave({
      url,
      altText: savedAltText,
      appliedHeight,
      appliedWidth,
      displayAs,
      isDecorativeImage
    })
  }

  useEffect(() => {
    let isValidURL
    try {
      isValidURL = validateURL(url)
    } catch (error) {
      isValidURL = false
    } finally {
      setShowUrlField(isValidURL ? isExternalUrl(url) : true)
    }
  }, [])

  const messagesForSize = []
  if (imageSize !== CUSTOM) {
    messagesForSize.push({
      text: formatMessage('{width} x {height}px', {height: imageHeight, width: imageWidth}),
      type: 'hint'
    })
  }

  const saveDisabled =
    url === '' ||
    (displayAs === 'embed' &&
      ((!isDecorativeImage && altText === '') ||
        (imageSize === CUSTOM && !dimensionsState?.isValid)))

  return (
    <Tray
      data-mce-component
      label={formatMessage('Image Options Tray')}
      onDismiss={onRequestClose}
      onEntered={onEntered}
      onExited={onExited}
      open={open}
      placement="end"
      shouldCloseOnDocumentClick
      shouldContainFocus
      shouldReturnFocus
    >
      <Flex direction="column" height={getTrayHeight()}>
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
            <Flex direction="column">
              {showUrlField && (
                <Flex.Item padding="small">
                  <UrlPanel fileUrl={url} setFileUrl={handleUrlChange} />
                </Flex.Item>
              )}
              <ImageOptionsForm
                id="image-options-form"
                imageSize={imageSize}
                displayAs={displayAs}
                isDecorativeImage={isDecorativeImage}
                altText={altText}
                isLinked={isLinked}
                dimensionsState={dimensionsState}
                handleAltTextChange={handleAltTextChange}
                handleIsDecorativeChange={handleIsDecorativeChange}
                handleDisplayAsChange={handleDisplayAsChange}
                handleImageSizeChange={handleImageSizeChange}
                messagesForSize={messagesForSize}
              />
            </Flex>
            <Flex.Item
              background="secondary"
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
    isLinked: bool,
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

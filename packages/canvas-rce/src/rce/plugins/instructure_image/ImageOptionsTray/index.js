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
import {bool, func, shape, string} from 'prop-types'
import {PresentationContent, ScreenReaderContent} from '@instructure/ui-a11y'
import {Button} from '@instructure/ui-buttons'
import {CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-elements'
import {Checkbox, RadioInput, RadioInputGroup, Select, TextArea} from '@instructure/ui-forms'
import {IconQuestionLine} from '@instructure/ui-icons'
import {Flex, View} from '@instructure/ui-layout'
import {Tooltip, Tray} from '@instructure/ui-overlays'

import formatMessage from '../../../../format-message'

function labelForImageSize(imageSize) {
  switch (imageSize) {
    case 'small': {
      return formatMessage('Small')
    }
    case 'medium': {
      return formatMessage('Medium')
    }
    case 'large': {
      return formatMessage('Large')
    }
    default: {
      return formatMessage('Custom')
    }
  }
}

export default function ImageOptionsTray(props) {
  const {imageOptions, onRequestClose, open} = props

  const [altText, setAltText] = useState(imageOptions.altText)
  const [isDecorativeImage, setIsDecorativeImage] = useState(imageOptions.isDecorativeImage)
  const [displayAs, setDisplayAs] = useState('embed')
  const [imageSize, setImageSize] = useState('medium')

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
  }

  function handleSave(event) {
    event.preventDefault()
    const savedAltText = isDecorativeImage ? '' : altText
    props.onSave({altText: savedAltText, displayAs, imageSize, isDecorativeImage})
  }

  const tooltipText = formatMessage('Used by screen readers to describe the content of an image')
  const textAreaLabel = (
    <Flex alignItems="center">
      <Flex.Item>{formatMessage('Alt Text')}</Flex.Item>

      <Flex.Item margin="0 0 0 xx-small">
        <PresentationContent>
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
        </PresentationContent>
      </Flex.Item>
    </Flex>
  )

  return (
    <Tray
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
              <CloseButton onClick={onRequestClose}>{formatMessage('Close')}</CloseButton>
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

                <Flex.Item margin="small none none none" padding="small">
                  <Select
                    label={formatMessage('Size')}
                    onChange={handleImageSizeChange}
                    selectedOption={imageSizeOption}
                  >
                    <option value="small">{labelForImageSize('small')}</option>

                    <option value="medium">{labelForImageSize('medium')}</option>

                    <option value="large">{labelForImageSize('large')}</option>

                    <option value="custom">{labelForImageSize('custom')}</option>
                  </Select>
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
                disabled={!isDecorativeImage && altText === '' && displayAs === 'embed'}
                onClick={handleSave}
                variant="primary"
              >
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
    isDecorativeImage: bool.isRequired
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

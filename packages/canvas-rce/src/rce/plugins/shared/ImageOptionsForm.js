/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import React from 'react'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Button} from '@instructure/ui-buttons'

import {Select} from '@instructure/ui-forms'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {TextArea} from '@instructure/ui-text-area'
import {Checkbox} from '@instructure/ui-checkbox'
import {IconQuestionLine} from '@instructure/ui-icons'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {Tooltip} from '@instructure/ui-tooltip'

import {
  CUSTOM,
  MIN_HEIGHT,
  MIN_WIDTH,
  imageSizes,
  labelForImageSize
} from '../instructure_image/ImageEmbedOptions'
import formatMessage from '../../../format-message'
import DimensionsInput from './DimensionsInput'

const ImageOptionsForm = ({
  imageSize,
  displayAs,
  isDecorativeImage,
  altText,
  dimensionsState,
  handleAltTextChange,
  handleIsDecorativeChange,
  handleDisplayAsChange,
  handleImageSizeChange,
  messagesForSize,
  handleSave,
  hideDimensions
}) => {
  const imageSizeOption = {label: labelForImageSize(imageSize), value: imageSize}

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

  const saveDisabled =
    displayAs === 'embed' &&
    ((!isDecorativeImage && altText === '') || (imageSize === CUSTOM && !dimensionsState?.isValid))

  return (
    <Flex justifyItems="space-between" direction="column" height="100%">
      <Flex.Item grow padding="small" shrink>
        <Flex direction="column">
          <Flex.Item padding="small">
            <TextArea
              disabled={isDecorativeImage}
              aria-describedby="alt-text-label-tooltip"
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
              label={formatMessage('Decorative Image')}
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
                disabled={isDecorativeImage}
                label={formatMessage('Display Text Link (Opens in a new tab)')}
                value="link"
              />
            </RadioInputGroup>
          </Flex.Item>

          {!hideDimensions && (
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
          )}
        </Flex>
      </Flex.Item>

      {handleSave && (
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
      )}
    </Flex>
  )
}

export default ImageOptionsForm

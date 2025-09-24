/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {ImageTextBlockLayoutProps} from './types'
import {Flex} from '@instructure/ui-flex'

export const ImageTextBlockLayout = ({
  titleComponent,
  textComponent,
  imageComponent,
  arrangement,
  textToImageRatio,
  dataTestId,
}: ImageTextBlockLayoutProps) => {
  const isLeftArrangement = arrangement === 'left'
  const direction = isLeftArrangement ? 'row' : 'row-reverse'
  const imagePadding = isLeftArrangement ? '0 xx-small 0 0' : '0 0 0 xx-small'
  const textPadding = isLeftArrangement ? '0 0 0 xx-small' : '0 xx-small 0 0'

  const isTextRatio1to1 = textToImageRatio === '1:1'
  const imageSize = isTextRatio1to1 ? '50%' : '33%'
  const textSize = isTextRatio1to1 ? '50%' : '67%'

  return (
    <Flex direction="column" gap="mediumSmall">
      {titleComponent}
      <Flex direction={direction} data-testid={dataTestId}>
        <Flex.Item size={imageSize} align="start" padding={imagePadding}>
          {imageComponent}
        </Flex.Item>
        <Flex.Item size={textSize} padding={textPadding} align="start">
          {textComponent}
        </Flex.Item>
      </Flex>
    </Flex>
  )
}

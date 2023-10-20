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

import React from 'react'
import {arrayOf, func, instanceOf, shape, bool, string} from 'prop-types'
import {Flex} from '@instructure/ui-flex'

import Image from './Image'

export default function ImageList({images, lastItemRef, onImageClick, isIconMaker, canvasOrigin}) {
  return (
    <Flex justifyItems="start" height="100%" margin="xx-small" padding="small" wrap="wrap">
      {images.map((image, index) => {
        let focusRef = null
        if (index === images.length - 1) {
          focusRef = lastItemRef
        }

        return (
          <Flex.Item
            as="div"
            key={'image-' + image.id}
            margin="xx-small xx-small small xx-small"
            size="6rem"
          >
            <Image
              focusRef={focusRef}
              image={image}
              onClick={onImageClick}
              isIconMaker={isIconMaker}
              canvasOrigin={canvasOrigin}
            />
          </Flex.Item>
        )
      })}
    </Flex>
  )
}

ImageList.propTypes = {
  images: arrayOf(Image.propTypes.image),
  lastItemRef: shape({
    current: instanceOf(Element),
  }).isRequired,
  onImageClick: func.isRequired,
  isIconMaker: bool,
  canvasOrigin: string.isRequired,
}

ImageList.defaultProps = {
  images: [],
  isIconMaker: false,
}

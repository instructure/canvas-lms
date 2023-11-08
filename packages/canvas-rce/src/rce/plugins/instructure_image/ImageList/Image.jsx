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
import {func, instanceOf, number, oneOfType, shape, string, bool} from 'prop-types'
import {Img} from '@instructure/ui-img'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {TruncateText} from '@instructure/ui-truncate-text'
import {View} from '@instructure/ui-view'

import dragHtml from '../../../../sidebar/dragHtml'
import formatMessage from '../../../../format-message'
import {renderImage} from '../../../contentRendering'

export default function Image({focusRef, image, onClick, isIconMaker, canvasOrigin}) {
  const imgTitle = formatMessage('Click to embed {imageName}', {
    imageName: image.display_name,
  })

  function handleDragStart(event) {
    dragHtml(event, renderImage(image, canvasOrigin))
  }

  function handleDragEnd() {
    document.body.click()
  }

  function handleImageClick(event) {
    event.preventDefault()
    onClick(image)
  }

  let elementRef = null
  if (focusRef) {
    elementRef = ref => {
      focusRef.current = ref
    }
  }

  return (
    <Link
      draggable={false}
      elementRef={elementRef}
      onClick={handleImageClick}
      onDragStart={handleDragStart}
    >
      <View
        as="div"
        borderRadius="medium"
        margin="none none small none"
        overflowX="hidden"
        overflowY="hidden"
      >
        <Img
          alt={image.display_name}
          constrain={isIconMaker ? 'contain' : 'cover'}
          draggable={true}
          height="6rem"
          display="block"
          onDragStart={handleDragStart}
          onDragEnd={handleDragEnd}
          src={image.thumbnail_url}
          title={imgTitle}
          width="6rem"
        />
      </View>

      <TruncateText>
        <Text size="small">{image.display_name}</Text>
      </TruncateText>
    </Link>
  )
}

Image.propTypes = {
  focusRef: shape({
    current: instanceOf(Element),
  }),
  image: shape({
    display_name: string.isRequired,
    filename: string,
    href: string.isRequired,
    id: oneOfType([number, string]),
    preview_url: string,
    thumbnail_url: string.isRequired,
  }).isRequired,
  onClick: func.isRequired,
  isIconMaker: bool,
  canvasOrigin: string.isRequired,
}

Image.defaultProps = {
  focusRef: null,
  isIconMaker: false,
}

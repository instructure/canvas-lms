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
import {func, number, shape, string} from 'prop-types'

import dragHtml from '../../../../sidebar/dragHtml'
import formatMessage from '../../../../format-message'
import {renderImage as renderImageHtml} from '../../../contentRendering'

const imgLinkStyles = {
  border: '1px solid #ccc',
  cursor: 'pointer',
  float: 'left',
  margin: '3px',
  overflow: 'hidden',
  padding: '3px'
}

export default function Image({image, onImageEmbed}) {
  const title = formatMessage('Click to embed image')
  const imgTitle = formatMessage('Click to embed {imageName}', {
    imageName: image.display_name
  })

  function handleDragStart(event) {
    dragHtml(event, renderImageHtml(image))
  }

  function handleImageClick(event) {
    event.preventDefault()
    onImageEmbed(image)
  }

  return (
    <a
      draggable={false}
      href={image.href}
      onClick={handleImageClick}
      onDragStart={handleDragStart}
      role="button"
      style={imgLinkStyles}
      title={title}
    >
      <div style={{minHeight: '50px'}}>
        <img
          alt={image.display_name}
          draggable
          onDragStart={handleDragStart}
          src={image.thumbnail_url}
          style={{maxHeight: 50, maxWidth: 200}}
          title={imgTitle}
        />
      </div>

      <div style={{wordBreak: 'break-all'}}>{image.display_name}</div>
    </a>
  )
}

Image.propTypes = {
  image: shape({
    display_name: string.isRequired,
    filename: string,
    href: string,
    id: number.isRequired,
    preview_url: string.isRequired,
    thumbnail_url: string
  }).isRequired,
  onImageEmbed: func.isRequired
}

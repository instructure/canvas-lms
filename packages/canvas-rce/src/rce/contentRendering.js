/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {renderToStaticMarkup} from 'react-dom/server'
import {cleanUrl} from './contentInsertionUtils'
import formatMessage from '../format-message'
import {
  VIDEO_SIZE_DEFAULT,
  AUDIO_PLAYER_SIZE,
} from './plugins/instructure_record/VideoOptionsTray/TrayController'
import {mediaPlayerURLFromFile} from './plugins/shared/fileTypeUtils'
import {prepEmbedSrc, prepLinkedSrc, absoluteToRelativeUrl} from '../common/fileUrl'

export function renderLink(data, contents, canvasOrigin) {
  const linkAttrs = {...data}
  linkAttrs.href = prepLinkedSrc(linkAttrs.href || linkAttrs.url)
  delete linkAttrs.url
  if (linkAttrs.href) {
    linkAttrs.href = absoluteToRelativeUrl(cleanUrl(linkAttrs.href), canvasOrigin)
  }
  linkAttrs.title = linkAttrs.title || formatMessage('Link')
  const children = contents || linkAttrs.text || linkAttrs.title
  delete linkAttrs.selectionDetails
  delete linkAttrs.text
  linkAttrs.className = linkAttrs.class
  delete linkAttrs.class

  // renderToStaticMarkup isn't happy with bool attributes
  Object.keys(linkAttrs).forEach(attr => {
    if (typeof linkAttrs[attr] === 'boolean') linkAttrs[attr] = linkAttrs[attr].toString()
  })

  return renderToStaticMarkup(<a {...linkAttrs}>{children}</a>)
}

export function renderLinkedImage(linkElem, image, canvasOrigin) {
  const linkHref = linkElem.getAttribute('href')
  image.href = prepEmbedSrc(image.href, canvasOrigin)

  return renderToStaticMarkup(
    <a href={absoluteToRelativeUrl(linkHref, canvasOrigin)} data-mce-href={linkHref}>
      {constructJSXImageElement(image, canvasOrigin, {doNotLink: true})}
    </a>
  )
}

export function constructJSXImageElement(image, canvasOrigin, opts = {}) {
  const {
    href,
    url,
    src,
    title,
    display_name,
    alt_text,
    isDecorativeImage,
    link,
    ...otherAttributes
  } = image
  const imageSrc = absoluteToRelativeUrl(href || url || src, canvasOrigin)
  let altText = alt_text || title || display_name || ''
  if (isDecorativeImage) {
    altText = ''
    otherAttributes.role = 'presentation'
  }

  delete otherAttributes.contextType // react doesn't like these
  delete otherAttributes.contextId

  const ret = (
    <img
      alt={altText}
      src={imageSrc}
      width={image.width}
      height={image.height}
      {...otherAttributes}
    />
  )
  if (link && !opts.doNotLink) {
    return (
      <a href={absoluteToRelativeUrl(link, canvasOrigin)} target="_blank" rel="noopener noreferrer">
        {ret}
      </a>
    )
  }
  return ret
}

export function renderImage(image, canvasOrigin, opts) {
  image.href = prepEmbedSrc(image.href, canvasOrigin)
  return renderToStaticMarkup(constructJSXImageElement(image, canvasOrigin, opts))
}

export function renderVideo(video, canvasOrigin) {
  const src = mediaPlayerURLFromFile(video, canvasOrigin)
  return `
  <iframe
      allow="fullscreen"
      allowfullscreen
      data-media-id="${getMediaId(video)}"
      data-media-type="video"
      src="${src}"
      style="width:${VIDEO_SIZE_DEFAULT.width};height:${
    VIDEO_SIZE_DEFAULT.height
  };display:inline-block;"
      title="${formatMessage('Video player for {title}', {
        title: video.title || video.name || video.text,
      })}"></iframe>
  `
    .trim()
    .replace(/\s+/g, ' ')
}

export function renderAudio(audio, canvasOrigin) {
  const src = mediaPlayerURLFromFile(audio, canvasOrigin)
  return `
  <iframe
      data-media-id="${getMediaId(audio)}"
      data-media-type="audio"
      src="${src}"
      style="width:${AUDIO_PLAYER_SIZE.width};height:${
    AUDIO_PLAYER_SIZE.height
  };display:inline-block;"
      title="${formatMessage('Audio player for {title}', {
        title: audio.title || audio.name || audio.text,
      })}"></iframe>
  `
    .trim()
    .replace(/\s+/g, ' ')
}

export function getMediaId(media) {
  if (!media) return

  return media.media_id || media.media_entry_id || media.id || media.file_id
}

export function updateImage(editor, img, attrs) {
  // Workaround: When passing empty string to editor.dom.setAttribs it removes the attribute
  img.setAttribute('alt', attrs.altText)
  editor.dom.setAttribs(img, {
    src: absoluteToRelativeUrl(attrs.url, editor.rceWrapper?.getCanvasUrl()),
    role: attrs.isDecorativeImage ? 'presentation' : null,
    width: attrs.appliedWidth,
    height: attrs.appliedHeight,
  })
}

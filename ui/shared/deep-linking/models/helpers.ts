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

import iframeAllowances from '@canvas/external-apps/iframeAllowances'

export type ContentItemIframe = {
  src: string
  width?: string | number
  height?: string | number
}
export type ContentItemThumbnail =
  | string
  | {url: string; width?: string | number; height?: string | number}

/**
 * Sanitizes a url for insertion into tinymce
 * @param url
 * @returns
 */
export const safeUrl = (url: string) => url.replace(/^(data:text\/html|javascript:)/, '#$1')

/**
 * Wraps innerHTML with an anchor tag,
 *
 * @param url an unsafe url
 * @param innerHTML the html to wrap in an anchor tag
 * @param title an optional title for the link
 * @returns
 */
export const anchorTag = (
  item: {
    url: string
    title?: string
  },
  innerHTML?: string
) => {
  const anchorTagEl = document.createElement('a')
  anchorTagEl.setAttribute('href', safeUrl(item.url))
  anchorTagEl.setAttribute('title', item.title || '')
  anchorTagEl.setAttribute('target', '_blank')
  anchorTagEl.innerHTML = innerHTML || ''
  return anchorTagEl.outerHTML
}

export const imageTag = (
  url: string,
  text?: string,
  width?: string | number,
  height?: string | number
) => {
  const imgTag = document.createElement('img')
  imgTag.setAttribute('src', url)

  if (text) {
    imgTag.setAttribute('alt', text)
  }

  if (width) {
    const widthStr = typeof width === 'number' ? width.toString() : width
    imgTag.setAttribute('width', widthStr)
  }

  if (height) {
    const heightStr = typeof height === 'number' ? height.toString() : height
    imgTag.setAttribute('height', heightStr)
  }

  return imgTag.outerHTML
}

export const linkThumbnail = (thumbnail: ContentItemThumbnail, text?: string) => {
  if (typeof thumbnail === 'object') {
    const {url, width, height} = thumbnail
    return imageTag(url, text, width, height)
  } else {
    return imageTag(thumbnail, text)
  }
}

export const iframeTag = (item: {title?: string; iframe: ContentItemIframe}) => {
  const iframe = item.iframe
  const iframeTag = document.createElement('iframe')

  iframeTag.setAttribute('src', iframe.src)
  iframeTag.setAttribute('title', item.title || '')
  iframeTag.setAttribute('allowfullscreen', 'true')
  iframeTag.setAttribute('allow', iframeAllowances())

  if (iframe.width) {
    iframeTag.style.width = `${iframe.width}px`
  }

  if (iframe.height) {
    iframeTag.style.height = `${iframe.height}px`
  }

  return iframeTag.outerHTML
}

export const linkText = (item: {text?: string; title?: string}) => {
  return (item.text && item.text.trim()) || (item.title && item.title.trim())
}

export const linkBody = (item: {
  text?: string
  title?: string
  thumbnail?: ContentItemThumbnail
}) => {
  if (item.thumbnail) {
    return linkThumbnail(item.thumbnail, item.text)
  } else {
    return linkText(item)
  }
}

export const renderLinkContentItem = (item: {
  iframe?: ContentItemIframe
  title?: string
  url: string
  thumbnail?: ContentItemThumbnail
}) => {
  if (typeof item.iframe?.src !== 'undefined') {
    return iframeTag({title: item.title, iframe: item.iframe})
  }

  return anchorTag(item, linkBody(item))
}

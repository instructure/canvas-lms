/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import ReactDOM from 'react-dom'
import formatMessage from '../format-message'
import {Spinner} from '@instructure/ui-spinner'
import {getData, setData} from './jqueryish_funcs'

export const previewableMimeTypes = [
  'application/vnd.openxmlformats-officedocument.wordprocessingml.template',
  'application/vnd.oasis.opendocument.spreadsheet',
  'application/vnd.sun.xml.writer',
  'application/excel',
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'text/rtf',
  'application/vnd.openxmlformats-officedocument.spreadsheetml.template',
  'application/vnd.sun.xml.impress',
  'application/vnd.sun.xml.calc',
  'application/vnd.ms-excel',
  'application/msword',
  'application/mspowerpoint',
  'application/rtf',
  'application/vnd.oasis.opendocument.presentation',
  'application/vnd.oasis.opendocument.text',
  'application/vnd.openxmlformats-officedocument.presentationml.template',
  'application/vnd.openxmlformats-officedocument.presentationml.slideshow',
  'text/plain',
  'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/postscript',
  'application/pdf',
  'application/vnd.ms-powerpoint',
]

// check to see if a file of a certan mimeType is previewable inline in the browser
// ex: isPreviewable("application/mspowerpoint")  -> true
export function isPreviewable(mimeType) {
  return previewableMimeTypes.includes(mimeType)
}

// Show a loading spinner
// The typical use is to show the spinner next to a canvas file link
// while the inline preview is loading. It's also used when previewing
// student submitted files in speedgrader, in which case $link is really
// the div containing the preview iframe. We handle these 2 cases by
// telling the function to put the spinner adjacent to $link,
// or to put it in the center of the preview container.
//
// $link: the DOM node that serves as the reference for locating the spinner
// position: one of 'adjacent' or 'centered'
export function showLoadingImage($link, position = 'adjacent') {
  const dir = ($link && window.getComputedStyle($link).direction) || 'ltr'
  const boundingBox = $link.getBoundingClientRect()
  const offsetLeft =
    boundingBox.left +
    (position === 'adjacent' ? (dir === 'ltr' ? boundingBox.width : -24) : boundingBox.width / 2)
  $link.style.marginInlineEnd = '28px'
  const imageMarginInlineStart = position === 'adjacent' ? '5px' : '-12px'
  const imageMarginTop = position === 'adjacent' ? 0 : '-12px'
  const zIndex = parseInt($link.style.zIndex || 0, 10) + 1
  const $imageHolder = document.createElement('div')
  $imageHolder.setAttribute('class', 'loading_image_holder')
  const list = getData($link, 'loading_images') || []
  list.push($imageHolder)
  setData($link, 'loading_images', list)

  if (!$link.style.position || $link.style.position === 'static') {
    const top = `${
      boundingBox.top + window.scrollY + (position === 'adjacent' ? 0 : boundingBox.height / 2)
    }px`
    const left = `${offsetLeft}px`

    $imageHolder.setAttribute(
      'style',
      `z-index: ${zIndex}; position: absolute; top: ${top}; left: ${left}; margin-inline-start: ${imageMarginInlineStart}; margin-top: ${imageMarginTop}`
    )
    document.body.appendChild($imageHolder)
  } else {
    const top = `${position === 'adjacent' ? 0 : boundingBox.height / 2}px`
    const left = `${offsetLeft}px`
    $imageHolder.setAttribute(
      'style',
      `z-index:${zIndex}; position: absolute; top: ${top}; left: ${left}; margin-inline-start:${imageMarginInlineStart}; margin-top: ${imageMarginTop}`
    )
    $link.appendChild($imageHolder)
  }
  ReactDOM.render(<Spinner size="x-small" renderTitle={formatMessage('Loading')} />, $imageHolder)
  return $link
}

export function removeLoadingImage($link) {
  $link.querySelector('.loading_image')?.remove()
  const list = getData($link, 'loading_images') || []
  list.forEach(item => {
    if (item) {
      item.remove()
    }
  })
  setData($link, 'loading_images', null)
  $link.style.marginInlineEnd = ''
  return $link
}

export function loadDocPreview($container, options) {
  let opts = {
    width: '100%',
    height: '400px',
    ...getData($container),
    ...options,
  }

  if (!$container) return // an issue in specs

  if (!($container instanceof HTMLElement)) {
    throw new Error('loadDocPreview requires a DOM element as first argument')
  }

  function tellAppIViewedThisInline() {
    // if I have a url to ping back to the app that I viewed this file inline, ping it.
    if (opts.attachment_view_inline_ping_url) {
      fetch(opts.attachment_view_inline_ping_url, {method: 'POST'})
    }
  }

  if (opts.crocodoc_session_url) {
    const sanitizedUrl = sanitizeUrl(opts.crocodoc_session_url)
    const iframe = document.createElement('iframe')
    iframe.setAttribute('src', sanitizedUrl)
    iframe.setAttribute('width', opts.width)
    iframe.setAttribute('height', opts.height)
    iframe.setAttribute('allowfullscreen', '1')
    iframe.id = opts.id
    $container.appendChild(iframe)
    iframe.load(() => {
      tellAppIViewedThisInline('crocodoc')
      if (typeof opts.ready === 'function') opts.ready()
    })
  } else if (opts.canvadoc_session_url) {
    const canvadocWrapper = document.createElement('div')
    canvadocWrapper.setAttribute(
      'style',
      'overflow: auto; resize: vertical; border: 1px solid transparent; height: 100%;'
    )
    $container.appendChild(canvadocWrapper)

    const minHeight = opts.iframe_min_height !== undefined ? opts.iframe_min_height : '800px'
    const sanitizedUrl = sanitizeUrl(opts.canvadoc_session_url)
    const iframe = document.createElement('iframe')
    iframe.addEventListener('load', () => {
      tellAppIViewedThisInline('canvadocs')
      if (typeof opts.ready === 'function') opts.ready()
    })
    iframe.setAttribute('src', sanitizedUrl)
    iframe.setAttribute('width', opts.width)
    iframe.setAttribute('allowfullscreen', '1')
    iframe.setAttribute('style', `border: 0; overflow: auto; height: 99%; min-height: ${minHeight}`)
    iframe.id = opts.id
    canvadocWrapper.appendChild(iframe)
  } else if (
    (!opts.disableGooglePreviews &&
      (!opts.mimetype || isPreviewable(opts.mimetype)) &&
      opts.attachment_id) ||
    opts.public_url
  ) {
    // else if it's something google docs preview can handle and we can get a public url to this document.
    const loadGooglePreview = function () {
      // this handles both ssl and plain http.
      const googleDocPreviewUrl = `//docs.google.com/viewer?${new URLSearchParams({
        embedded: true,
        url: opts.public_url,
      }).toString()}`
      if (!opts.ajax_valid || opts.ajax_valid()) {
        const iframe = document.createElement('iframe')
        iframe.addEventListener('load', () => {
          tellAppIViewedThisInline('google')
          if (typeof opts.ready === 'function') {
            opts.ready()
          }
        })
        iframe.setAttribute('src', googleDocPreviewUrl)
        iframe.setAttribute('height', opts.height)
        iframe.setAttribute('width', '100%')
        $container.appendChild(iframe)
      }
    }
    if (opts.public_url) {
      loadGooglePreview()
    } else if (opts.attachment_id) {
      let url = `/api/v1/files/${opts.attachment_id}/public_url.json`
      if (opts.submission_id) {
        url += '?' + new URLSearchParams({submission_id: opts.submission_id}).toString()
      }
      if (opts.verifier) {
        url += `${opts.submission_id ? '&' : '?'}verifier=${opts.verifier}`
      } else {
        const match = window.location.search.match(/verifier=([^&]+)(?:&|$)/)
        const ver = match && match[1]
        if (ver) {
          url += `${opts.submission_id ? '&' : '?'}verifier=${ver}`
        }
      }
      showLoadingImage($container, 'centered')
      // eslint-disable-next-line promise/catch-or-return
      fetch(url)
        .then(response => {
          if (!response.ok) throw new Error(`${response.status}: ${response.statusText}`)
          return response
        })
        .then(response => response.json())
        .then(data => {
          if (data.public_url) {
            opts = {...opts, ...data}
            loadGooglePreview()
          }
        })
        .catch(ex => {
          // eslint-disable-next-line no-console
          console.error(ex)
        })
        .finally(() => {
          removeLoadingImage($container)
        })
    }
  } else {
    // else fall back with a message that the document can't be viewed inline
    const paragraph = document.createElement('p')
    if (opts.attachment_preview_processing) {
      paragraph.textContent = formatMessage(
        'The document preview is currently being processed. Please try again later.'
      )
    } else {
      paragraph.textContent = formatMessage('This document cannot be displayed within Canvas.')
    }
    $container.empty().append(paragraph)
  }
}

/**
 * Replaces bad urls with harmless urls in cases where bad urls might cause harm
 * @param {string} url
 */
export function sanitizeUrl(url) {
  const defaultUrl = 'about:blank'
  try {
    const parsedUrl = new URL(url, window.location.origin)
    // eslint-disable-next-line no-script-url
    if (parsedUrl.protocol === 'javascript:') {
      return defaultUrl
    }
    return url
  } catch (e) {
    // URL() throws TypeError if url is not a valid URL
    return defaultUrl
  }
}

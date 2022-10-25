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

import htmlEscape from 'escape-html'
import formatMessage from '../format-message'
import {showFlashAlert} from '../common/FlashAlert'
import {isPreviewable, loadDocPreview, showLoadingImage, removeLoadingImage} from './doc_previews'
import {show} from './jqueryish_funcs'

const youTubeRegEx = /^https?:\/\/(www\.youtube\.com\/watch.*v(=|\/)|youtu\.be\/)([^&#]*)/
export function youTubeID(path) {
  const match = path.match(youTubeRegEx)
  if (match && match[match.length - 1]) {
    return match[match.length - 1]
  }
  return null
}

export function getTld(hostname) {
  hostname = (hostname || '').split(':')[0]
  const parts = hostname.split('.'),
    length = parts.length
  return (length > 1 ? [parts[length - 2], parts[length - 1]] : parts).join('.')
}
const locationTld = getTld(window.location.hostname)

export function isExternalLink(element) {
  const href = element.getAttribute('href')
  // if a browser doesnt support <a>.hostname then just dont mark anything as external, better to not get false positives.
  return !!(
    href &&
    href.length &&
    !href.match(/^(mailto\:|javascript\:)/) &&
    element.hostname &&
    getTld(element.hostname) !== locationTld
  )
}

export function showFilePreview(canvasOrigin, event) {
  let target = null
  if (event.target?.href) {
    target = event.target
  } else if (event.currentTarget?.href) {
    target = event.currentTarget
  } else {
    return
  }

  if (target.classList.contains('no_preview')) {
    return
  }
  if (
    target.classList.contains('inline_disabled') ||
    target.classList.contains('preview_in_overlay')
  ) {
    showFilePreviewInOverlay(canvasOrigin, event)
  } else {
    showFilePreviewInline(event)
  }
}

export function showFilePreviewInOverlay(canvasOrigin, event) {
  let target = null
  if (event.target?.href) {
    target = event.target
  } else if (event.currentTarget?.href) {
    target = event.currentTarget
  }
  const matches = target?.href.match(/\/files\/(\d+)/)
  if (matches) {
    if (event.ctrlKey || event.altKey || event.metaKey || event.shiftKey) {
      // if any modifier keys are pressed, do the browser default thing
      return
    }
    event.preventDefault()
    const url = new URL(target.href)
    const verifier = url?.searchParams.get('verifier')
    const file_id = matches[1]
    // TODO:
    // 1. what window should be be using
    // 2. is that the right origin?
    // 3. this is temporary until we can decouple the file previewer from canvas
    window.top.postMessage({subject: 'preview_file', file_id, verifier}, canvasOrigin)
  }
}

export function showFilePreviewInline(event) {
  if (event.ctrlKey || event.altKey || event.metaKey || event.shiftKey) {
    // if any modifier keys are pressed, do the browser default thing
    return
  }
  event.preventDefault()
  const $link = event.currentTarget || event.target
  if ($link.getAttribute('aria-expanded') === 'true') {
    // close the preview by clicking the "Minimize File Preview" link
    const $preview = document.getElementById($link.getAttribute('aria-controls'))
    $preview.querySelector('.hide_file_preview_link').click()
    return
  }
  showLoadingImage($link)
  fetch(
    $link
      .getAttribute('href')
      .replace(/\/(download|preview)/, '') // download as part of the path
      .replace(/wrap=1&?/, '') // wrap=1 as part of the query_string
      .replace(/[?&]$/, ''), // any trailing chars if wrap=1 was at the end
    {
      method: 'GET',
      headers: {Accept: 'application/json'},
    }
  )
    .then(response => {
      if (!response.ok) throw new Error(`${response.status}: ${response.statusText}`)
      return response
    })
    .then(response => response.json())
    .then(data => {
      const attachment = data && data.attachment
      removeLoadingImage($link)
      if (
        attachment &&
        (isPreviewable(attachment.content_type, 'google') || attachment.canvadoc_session_url)
      ) {
        $link.setAttribute('aria-expanded', 'true')

        const $div = document.querySelector(`[id="${$link.getAttribute('aria-controls')}"]`)
        $div.style.display = 'block'
        loadDocPreview($div, {
          canvadoc_session_url: attachment.canvadoc_session_url,
          mimeType: attachment.content_type,
          public_url: attachment.public_url,
          attachment_preview_processing:
            attachment.workflow_state === 'pending_upload' ||
            attachment.workflow_state === 'processing',
        })
        const $minimizeLink = document.createElement('a')
        $minimizeLink.setAttribute('href', '#')
        $minimizeLink.setAttribute('style', 'font-size: 0.8em;')
        $minimizeLink.setAttribute('class', 'hide_file_preview_link')
        $minimizeLink.innerHTML = htmlEscape(formatMessage('Minimize File Preview'))
        $minimizeLink.addEventListener('click', event2 => {
          event2.preventDefault()
          resetInlinePreview($link, $div)
        })
        $div.prepend($minimizeLink)
        if (Object.prototype.hasOwnProperty.call(event, 'originalEvent')) {
          // Only focus this link if the open preview link was initiated by a real browser event
          // If it was triggered by our auto_open stuff it shouldn't focus here.
          $minimizeLink.focus()
        }
      }
    })
    .catch(ex => {
      showFlashAlert({
        message: formatMessage('Failed getting file contents'),
        type: 'error',
      })
      // eslint-disable-next-line no-console
      console.error(ex)
      resetInlinePreview($link)

      removeLoadingImage($link)
    })
}

function resetInlinePreview($link, $previewContainer) {
  $link.setAttribute('aria-expanded', 'false')
  show($link)
  $link.focus()
  if ($previewContainer) {
    $previewContainer.innerHTML = ''
    $previewContainer.style.display = 'none'
  }
}

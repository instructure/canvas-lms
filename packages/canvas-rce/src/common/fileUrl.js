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

// I really want to use the native URL api, but it's requirement of an absolute URL
// or a base URL makes testing difficult, esp since window.location is "about:blank"
// in mocha tests.
import {parse, format} from 'url'

function parseCanvasUrl(url, canvasOrigin = window.location.origin) {
  if (!url) {
    return null
  }
  const parsed = parse(url, true)
  const canvasHost = parse(canvasOrigin, true).host
  if (parsed.host && canvasHost !== parsed.host) {
    return null
  }
  return parsed
}

export function absoluteToRelativeUrl(url, canvasOrigin) {
  const parsed = parseCanvasUrl(url, canvasOrigin)
  if (!parsed) {
    return url
  }
  parsed.host = ''
  parsed.hostname = ''
  parsed.slashes = false
  parsed.protocol = ''
  const newUrl = format(parsed)
  return newUrl
}

function changeDownloadToWrapParams(parsedUrl) {
  delete parsedUrl.search
  delete parsedUrl.query.download_frd
  parsedUrl.query.wrap = '1'
  parsedUrl.pathname = parsedUrl.pathname.replace(/\/(?:download|preview)\/?$/, '')
  return parsedUrl
}

function addContext(parsedUrl, contextType, contextId) {
  // if this is a http://canvas/files... url. change it to be contextual
  if (/^\/files/.test(parsedUrl.pathname)) {
    const context = contextType.replace(/([^s])$/, '$1s') // canvas contexts are plural
    parsedUrl.pathname = `/${context}/${contextId}${parsedUrl.pathname}`
  }
  return parsedUrl
}

// simply replaces the download_frd url param with wrap
// wrap=1 will (often) cause the resource to be loaded
// in an iframe on canvas' files page
export function downloadToWrap(url) {
  const parsed = parseCanvasUrl(url)
  if (!parsed) {
    return url
  }
  return format(changeDownloadToWrapParams(parsed))
}

// take a url to a file (e.g. /files/17), and convert it to
// it's in-context url (e.g. /courses/2/files/17).
// Add wrap=1 to the url so it previews, not downloads
// If it is a user file or being referenced from a different origin, add the verifier
// NOTE: this can be removed once canvas-rce-api is updated
//       to normalize the file URLs it returns.
export function fixupFileUrl(contextType, contextId, fileInfo, canvasOrigin) {
  // it's annoying, but depending on how we got here
  // the file may have an href or a url
  const key = fileInfo.href ? 'href' : 'url'
  if (fileInfo[key]) {
    let parsed = parseCanvasUrl(fileInfo[key], canvasOrigin)
    if (!parsed) {
      return fileInfo
    }
    parsed = changeDownloadToWrapParams(parsed)
    parsed = addContext(parsed, contextType, contextId)
    // if this is a user file, add the verifier
    if (fileInfo.uuid && contextType.includes('user')) {
      delete parsed.search
      parsed.query.verifier = fileInfo.uuid
    } else {
      delete parsed.query.verifier
    }
    fileInfo[key] = format(parsed)
  }
  return fileInfo
}

// embedded resources, like an <img src=url> with /preview
// in the url will not be logged as a view in canvas.
// This is appropriate for images in some rce content.
// Remove wrap=1 to indicate we want the file downloaded
// (which is necessary to show in an <img> tag), not viewed
export function prepEmbedSrc(url, canvasOrigin = window.location.origin) {
  const parsed = parseCanvasUrl(url, canvasOrigin)
  if (!parsed) {
    return url
  }
  if (!/\/preview(?:\?|$)/.test(parsed.pathname)) {
    parsed.pathname = parsed.pathname.replace(/(?:\/download)?\/?(\?|$)/, '/preview$1')
  }
  delete parsed.search
  delete parsed.query.wrap
  return format(parsed)
}

// when the user opens a link to a resource, we want its view
// logged, so remove /preview
export function prepLinkedSrc(url) {
  const parsed = parseCanvasUrl(url)
  if (!parsed) {
    return url
  }
  delete parsed.search
  parsed.pathname = parsed.pathname.replace(/\/preview(\?|$)/, '$1')
  return format(parsed)
}

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

import RCEGlobals from '../rce/RCEGlobals'

interface ParsedUrl {
  pathname: string | null
  search: string | null
  hash: string | null
  host: string | null
  hostname: string | null
  protocol: string | null
  query: Record<string, string>
  slashes?: boolean
}

const CONTACT_PROTOCOLS = ['mailto:', 'tel:', 'skype:'];

function parseUrl(url: string, canvasOrigin: string = window.location.origin): URL {
  try {
    // If the URL is already absolute, use it as-is
    return new URL(url)
  } catch {
    return new URL(`${canvasOrigin}${url.startsWith('/') ? '' : '/'}${url}`)
  }
}

function parseCanvasUrl(
  url: string | undefined | null,
  canvasOrigin: string = window.location.origin,
): ParsedUrl | null {
  if (!url) {
    return null
  }

  try {
    const parsed = parseUrl(url, canvasOrigin)
    const canvasUrl = new URL(canvasOrigin)

    if (parsed.host && canvasUrl.host !== parsed.host) {
      return null
    }

    if (CONTACT_PROTOCOLS.includes(parsed.protocol)) {
      return null
    }

    // Convert URLSearchParams to query object
    const query: Record<string, string> = {}
    parsed.searchParams.forEach((value, key) => {
      query[key] = value
    })

    return {
      pathname: parsed.pathname,
      search: parsed.search,
      hash: parsed.hash,
      host: parsed.host,
      hostname: parsed.hostname,
      protocol: parsed.protocol,
      query,
    }
  } catch {
    // If URL parsing fails, return null
    return null
  }
}

function formatUrl(parsed: ParsedUrl): string {
  try {
    // Format query string while preserving original encoding
    const queryPairs = Object.entries(parsed.query || {}).map(([key, value]) => {
      // Use encodeURIComponent to preserve %20 encoding
      return `${encodeURIComponent(key)}=${encodeURIComponent(value)}`
    })
    const search = queryPairs.join('&')
    const pathname = parsed.pathname || ''
    const hash = parsed.hash || ''

    if (parsed.protocol || parsed.host) {
      const protocol = parsed.protocol ? parsed.protocol.replace(/:$/, '') : ''
      const host = parsed.host || ''
      return `${protocol}://${host}${pathname}${search ? '?' + search : ''}${hash}`
    }

    return `${pathname}${search ? '?' + search : ''}${hash}`
  } catch {
    return ''
  }
}

export function absoluteToRelativeUrl(url: string, canvasOrigin?: string): string {
  const parsed = parseCanvasUrl(url, canvasOrigin || window.location.origin)
  if (!parsed) {
    return url
  }
  parsed.host = ''
  parsed.hostname = ''
  parsed.protocol = ''
  return formatUrl(parsed)
}

function changeDownloadToWrapParams(parsedUrl: ParsedUrl): ParsedUrl {
  if (parsedUrl.search) {
    parsedUrl.search = null
  }
  if (parsedUrl.query) {
    // Remove all download-related parameters
    delete parsedUrl.query.download_frd
  }
  if (!parsedUrl.query) {
    parsedUrl.query = {}
  }
  parsedUrl.query.wrap = '1'
  if (parsedUrl.pathname) {
    parsedUrl.pathname = parsedUrl.pathname.replace(/\/(?:download|preview)\/?$/, '')
  }
  return parsedUrl
}

function addContext(
  parsedUrl: ParsedUrl,
  contextType: string,
  contextId: string | number,
): ParsedUrl {
  // if this is a http://canvas/files... url. change it to be contextual
  if (parsedUrl.pathname && /^\/files/.test(parsedUrl.pathname)) {
    const context = contextType.replace(/([^s])$/, '$1s') // canvas contexts are plural
    parsedUrl.pathname = `/${context}/${contextId}${parsedUrl.pathname}`
  }
  return parsedUrl
}

// simply replaces the download_frd url param with wrap
// wrap=1 will (often) cause the resource to be loaded
// in an iframe on canvas' files page
export function downloadToWrap(url: string): string {
  const parsed = parseCanvasUrl(url)
  if (!parsed) {
    return url
  }
  const formattedUrl = formatUrl(changeDownloadToWrapParams(parsed))
  return absoluteToRelativeUrl(formattedUrl)
}

// take a url to a file (e.g. /files/17), and convert it to
// it's in-context url (e.g. /courses/2/files/17).
// Add wrap=1 to the url so it previews, not downloads
// If it is a user file or being referenced from a different origin, add the verifier
// NOTE: this can be removed once canvas-rce-api is updated
//       to normalize the file URLs it returns.
export function fixupFileUrl(
  // it's annoying, but depending on how we got here
  // the file may have an href or a url
  contextType: string,
  contextId: string | number,
  fileInfo: {href?: string; url?: string; uuid?: string},
  canvasOrigin?: string,
): {href?: string; url?: string; uuid?: string} {
  const key = fileInfo.href ? 'href' : 'url'
  if (fileInfo[key]) {
    const currentOrigin = canvasOrigin || window.location.origin
    let parsed = parseCanvasUrl(fileInfo[key], currentOrigin)
    if (!parsed) {
      return fileInfo
    }
    parsed = changeDownloadToWrapParams(parsed)
    parsed = addContext(parsed, contextType, contextId)
    // if this is a user file, add the verifier
    // if this is in New Quizzes and the feature flag is enabled, add the verifier

    if (
      fileInfo.uuid &&
      (contextType.includes('user') ||
        (!!canvasOrigin &&
          canvasOrigin !== window.location.origin &&
          RCEGlobals.getFeatures()?.file_verifiers_for_quiz_links))
    ) {
      parsed.search = null
      parsed.query.verifier = fileInfo.uuid
    } else {
      delete parsed.query.verifier
    }
    const formattedUrl = formatUrl(parsed)

    // Keep absolute URLs if they match the canvas origin and input was absolute
    const isAbsoluteUrl = fileInfo[key]?.startsWith('http')
    const matchesCanvasOrigin = fileInfo[key]?.startsWith(currentOrigin)
    fileInfo[key] =
      isAbsoluteUrl && matchesCanvasOrigin
        ? formattedUrl
        : absoluteToRelativeUrl(formattedUrl, currentOrigin)
  }
  return fileInfo
}

// embedded resources, like an <img src=url> with /preview
// in the url will not be logged as a view in canvas.
// This is appropriate for images in some rce content.
// Remove wrap=1 to indicate we want the file downloaded
// (which is necessary to show in an <img> tag), not viewed
export function prepEmbedSrc(url: string, canvasOrigin: string = window.location.origin): string {
  const parsed = parseCanvasUrl(url, canvasOrigin)
  if (!parsed) {
    return url
  }
  if (parsed.pathname && !/\/preview(?:\?|$)/.test(parsed.pathname)) {
    parsed.pathname = parsed.pathname.replace(/(?:\/download)?\/?(\?|$)/, '/preview$1')
  }
  parsed.search = null
  delete parsed.query.wrap
  const formattedUrl = formatUrl(parsed)

  // Keep absolute URLs if they match the canvas origin
  const isAbsoluteUrl = url.startsWith('http')
  const matchesCanvasOrigin = url.startsWith(canvasOrigin)
  return isAbsoluteUrl && matchesCanvasOrigin
    ? formattedUrl
    : absoluteToRelativeUrl(formattedUrl, canvasOrigin)
}

// when the user opens a link to a resource, we want its view
// logged, so remove /preview
export function prepLinkedSrc(url: string): string {
  const parsed = parseCanvasUrl(url)
  if (!parsed) {
    return url
  }
  if (parsed.pathname) {
    parsed.pathname = parsed.pathname.replace(/\/preview(?:\?|$)/, '')
  }
  const formattedUrl = formatUrl(parsed)
  return absoluteToRelativeUrl(formattedUrl)
}

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

import {parse, format} from 'url'

// simply replaces the download_frd url param with wrap
// wrap=1 will (often) cause the resource to be loaded
// in an iframe on canvas' files page
export function downloadToWrap(url) {
  if (!url) {
    return url
  }
  const parsed = parse(url, true)
  if (parsed.host && window.location.host !== parsed.host) {
    return url
  }
  delete parsed.search
  delete parsed.query.download_frd
  parsed.query.wrap = 1

  return format(parsed)
}

// take a url to a file (e.g. /files/17), and convert it to
// it's in-context url (e.g. /courses/2/files/17).
// If it's not a user file, add wrap=1 to the url so it's
// displayed w/in the files page.
// and if it is a user file, add the verifier
export function fixupFileUrl(contextType, contextId, fileInfo) {
  // it's annoying, but depending on how we got here
  // the file may have an href or a url
  const key = fileInfo.href ? 'href' : 'url'
  if (fileInfo[key]) {
    const parsed = parse(fileInfo[key], true)
    if (!parsed.host || window.location.host === parsed.host) {
      // only fixup our urls

      delete parsed.search
      delete parsed.query.download_frd
      if (!contextType.includes('user')) {
        // user files "wrapped" in the /user/:id/files/:id page
        // result in access denied for other users
        parsed.query.wrap = 1
      }

      // if this is a http://canvas/files... url. change it to be contextual
      if (/^\/files/.test(parsed.pathname)) {
        const context = contextType.replace(/([^s])$/, '$1s') // canvas contexts are plural
        parsed.pathname = `/${context}/${contextId}${parsed.pathname}`
      }

      // if this is a user file, add the verifier
      if (fileInfo.uuid && contextType.includes('user')) {
        delete parsed.search
        parsed.query.verifier = fileInfo.uuid
      }
      fileInfo[key] = format(parsed)
    }
  }
  return fileInfo
}

// embedded resources, like an <img src=url> with /preview
// in the url will not be logged as a view in canvas.
// This is appropriate for images in some rce content.
export function prepEmbedSrc(url) {
  if (!url) {
    return url
  }
  const parsed = parse(url, true)
  if (parsed.host && window.location.host !== parsed.host) {
    return url
  }
  parsed.pathname = parsed.pathname.replace(/\/download(\?|$)/, '/preview$1')
  return format(parsed)
}

// when the user opens a link to a resource, we want its view
// logged, so remove /preview. We may have to switch from an
// embedded style url to a link style if the user converts
// an image to a link in the rce's image options tray.
export function prepLinkedSrc(url) {
  if (!url) {
    return url
  }
  const parsed = parse(url, true)
  if (parsed.host && window.location.host !== parsed.host) {
    return url
  }
  parsed.pathname = parsed.pathname.replace(/\/preview(\?|$)/, '/download$1')
  return format(parsed)
}

/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import formatMessage from '../../../format-message'

// Keep in sync with the protocols permitted for <a href>
//   as listed in gems/canvas_sanitize/lib/canvas_sanitize/canvas_sanitize.rb
const allowed_protocols = ['ftp:', 'http:', 'https:', 'mailto:', 'tel:', 'skype:']

/**
 * Weakly validate a URL
 * @param {string} url URL to validate
 * @returns {boolean} true if valid, false if not valid yet, but incomplete, throws if invalid
 */
export default function validateURL(url) {
  const href = url.trim()

  // Handle special cases for partial URLs
  if (href === '' || href === 'mailto:' || href === 'tel:' || href === 'skype:') {
    return false
  }
  if (/^\/\/$/.test(href)) {
    return false
  }

  try {
    // Handle URLs starting with :// (invalid protocol)
    if (href.startsWith('://')) {
      throw new Error(
        formatMessage('Protocol must be ftp, http, https, mailto, skype, tel or may be omitted'),
      )
    }

    // For URLs with protocols, we can use the URL constructor directly
    if (/^[a-zA-Z][a-zA-Z\d+.-]*:/.test(href)) {
      const protocol = href.substring(0, href.indexOf(':') + 1)
      if (!allowed_protocols.includes(protocol)) {
        throw new Error(formatMessage('{p} is not a valid protocol.', {p: protocol.slice(0, -1)}))
      }

      // For absolute URLs with protocols that require //, validate the format
      if (['http:', 'https:', 'ftp:'].includes(protocol) && !href.startsWith(protocol + '//')) {
        throw new Error(formatMessage('Invalid URL'))
      }

      // Special handling for mailto:, tel:, and skype: URLs
      if (['mailto:', 'tel:', 'skype:'].includes(protocol)) {
        // Consider protocol:// as incomplete for these protocols
        if (href === protocol + '//' || href === protocol + '///') {
          return false
        }
        return href.length > protocol.length
      }

      // Handle partial URLs
      if (href === protocol || href === protocol + '/' || href === protocol + '//') {
        return false
      }

      // Try constructing the URL to validate the format
      try {
        if (href.includes('//')) {
          new URL(href)
        }
        return true
      } catch {
        // If URL construction fails but we have more than just protocol://, consider it valid
        // This allows for test URLs like ftp://host:port/path
        return href.length > protocol.length + 2
      }
    }

    // Handle protocol-relative URLs
    if (href.startsWith('//')) {
      if (href === '//' || href === '///') {
        return false
      }
      try {
        new URL('http:' + href)
        return true
      } catch {
        // If URL construction fails but we have more than just //, consider it valid
        return href.length > 2
      }
    }

    // Handle relative paths
    return true
  } catch (e) {
    if (e instanceof Error) {
      if (e.message.includes('Invalid URL')) {
        if (href.match(/^(https?|ftp):\/?\/?$/)) {
          return false
        }
        throw new Error(formatMessage('Invalid URL'))
      }
      throw e
    }
    throw e
  }
}

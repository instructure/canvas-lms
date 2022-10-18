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

import {parse} from 'url'
import formatMessage from '../../../format-message'

// keep in sync with the protocols permitted for <a href>
// as listed in gems/canvas_sanitize/lib/canvas_sanitize/canvas_sanitize.rb
const allowed_protocols = ['ftp:', 'http:', 'https:', 'mailto:', 'tel:', 'skype:']

// weakly validate a url
// return true if valid
// return false if not valid yet, but incomplete
// throw an Error if invalid
export default function validateURL(url) {
  const href = url.trim()
  const parsed = parse(href, false, true)
  const protocol = parsed.protocol
  if (!protocol) {
    if (parsed.href[0] === ':') {
      // ":anything" is invalid
      // need this check as an artifact of parse(href)
      throw new Error(
        formatMessage('Protocol must be ftp, http, https, mailto, skype, tel or may be omitted')
      )
    }
    if (/^\/\/$/.test(href)) {
      // "//" by itself is not a URL yet
      return false
    }
  } else if (protocol) {
    if (!allowed_protocols.includes(protocol)) {
      throw new Error(
        formatMessage(
          '{p} is not a valid protocol which must be ftp, http, https, mailto, skype, tel or may be omitted',
          {
            p: protocol.replace(/:$/, ''),
          }
        )
      )
    }

    // ftp, http, https require ://anything
    if (/(?:ftp|http|https):\/\/.+/.test(href)) {
      return true
    }

    // allow mailto:address, skype:participant, tel:911 or
    // mailto://address, skype://participant, tel://911,
    if (/(?:mailto|skype|tel):(\/\/)?[^/].*/.test(href)) {
      return true
    }

    // http:/xyzzy is invalid
    if (/^(?:ftp|http|https):\/{0,1}[^/]/.test(href)) {
      throw new Error(formatMessage('Invalid URL'))
    }

    return false
  }
  return true
}

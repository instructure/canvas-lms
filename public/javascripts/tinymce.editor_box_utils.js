/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

/**
 * A collection of functions that extract business logic
 * from the sphaghetti that is tinymce.editor_box.js
 *
 * They're all exported as self contained functions that hang off this
 * namespace with no global state
 * in this module because that's what has been really hurting debugging
 * efforts around tinymce issues in the past.
 *
 * functions in this module SHOULD NOT have side effects,
 * but should be focused around providing necessary data
 * or dom transformations with no state in this file.
 * @exports
 */

/**
 * transforms an input url to make a link out of
 * into a correctly formed url.  If it's clearly a mailing link,
 * adds mailto: to the front, and if it has no protocol but isn't an
 * absolute path, it prepends "http://".
 *
 * @param {string} input the raw url representative input by a user
 *
 * @returns {string} a well formed url
 */
export function cleanUrl(input) {
  let url = input
  if (url.includes('@') && !url.includes('/') && !input.startsWith('mailto:')) {
    url = `mailto:${input}`
  } else if (!input.match(/^\w+:\/\//) && !input.startsWith('mailto:') && !input.startsWith('/')) {
    url = `http://${input}`
  }

  if (url.includes('@') && !url.startsWith('mailto:') && !url.startsWith('http')) {
    url = `mailto:${url}`
  }
  return url
}

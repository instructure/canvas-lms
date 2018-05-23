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

/**
 * functions in this module SHOULD NOT have side effects,
 * but should be focused around providing necessary data
 * or dom transformations with no state in this file.
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
  var url = input;
  if (input.match(/@/) && !input.match(/\//) && !input.match(/^mailto:/)) {
    url = "mailto:" + input;
  } else if (
    !input.match(/^\w+:\/\//) &&
    !input.match(/^mailto:/) &&
    !input.match(/^\//)
  ) {
    url = "http://" + input;
  }

  if (
    url.indexOf("@") != -1 &&
    url.indexOf("mailto:") != 0 &&
    !url.match(/^http/)
  ) {
    url = "mailto:" + url;
  }
  return url;
}

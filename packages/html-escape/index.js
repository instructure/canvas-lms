/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

const INST = {}

if (!('INST' in window)) window.INST = {}

/**
 * Represents a string that is safe to use in HTML or other contexts where
 * escaping is important. This class wraps a standard string and marks it as safe,
 * meaning that it should not be further escaped when rendered. This is useful
 * in templating engines or other contexts where you have pre-escaped strings
 * or strings with HTML content that should be rendered as-is.
 */
class SafeString {
  /**
   * @param {string | any} string - The string or value to be marked as safe. If not a string, it will be converted to one.
   */
  constructor(string) {
    this.string = typeof string === 'string' ? string : `${string}`
  }

  /**
   * @returns {string} The original string marked as safe.
   */
  toString() {
    return this.string
  }
}

/**
 * Wraps a given string in a SafeString object to mark it as safe for raw HTML interpolation.
 * This is particularly useful for internationalization (i18n), where you might need to insert
 * HTML elements into localized strings. Note that SafeString returns an object designed
 * to be recognized by templating engines as safe to render without further escaping.
 * If you are using the result in a context where a string is expected, you may need to call `toString()`.
 *
 * @param {string} str - The string to be wrapped as a SafeString.
 * @returns {SafeString} An object representing the safe HTML string.
 *
 * @example
 * // Example usage for internationalization with HTML content
 * t('key', 'pick one: %{select}', { select: raw('<select><option>...') })
 */
export const raw = function (str) {
  return new SafeString(str)
}

const ENTITIES = {
  '&': '&amp;',
  '<': '&lt;',
  '>': '&gt;',
  '"': '&quot;',
  "'": '&#x27;',
  '/': '&#x2F;',
  '`': '&#x60;',
  '=': '&#x3D;',
}

/**
 * @param {string} str - The string to be escaped.
 * @returns {string} The escaped string with HTML special characters replaced by entities.
 *
 * @example
 * // Example of escaping a string with HTML content
 * const unsafeString = "<script>alert('XSS')</script>";
 * const safeString = htmlEscape(unsafeString);
 * // safeString would be: "&lt;script&gt;alert('XSS')&lt;/script&gt;"
 */
export function htmlEscape(str) {
  return str.replace(/[&<>"'\/`=]/g, c => ENTITIES[c])
}

/**
 * @template T The type of the input, either string, number, or object.
 * @param {T} strOrObject - The input to be escaped. Can be a string, number, or an object.
 * @returns {T extends string | number ? string : T} The escaped string, or the object with all its string values escaped.
 *
 * @example
 * // Escaping a string
 * const unsafeString = "<script>alert('XSS')</script>";
 * const safeString = escape(unsafeString);
 *
 * @example
 * // Escaping a number
 * const number = 123;
 * const safeNumber = escape(number); // "123"
 *
 * @example
 * // Escaping an object
 * const obj = { key: "Value <script>alert('XSS')</script>" };
 * const safeObj = escape(obj); // { key: "&lt;script&gt;alert('XSS')&lt;/script&gt;" }
 */
export default function escape(strOrObject) {
  if (typeof strOrObject === 'string') {
    return htmlEscape(strOrObject)
  } else if (strOrObject instanceof SafeString) {
    return strOrObject
  } else if (typeof strOrObject === 'number') {
    return escape(strOrObject.toString())
  }

  for (const k in strOrObject) {
    if (strOrObject.hasOwnProperty(k)) {
      const v = strOrObject[k]
      strOrObject[k] = escape(v)
    }
  }
  return strOrObject
}
escape.SafeString = SafeString

INST.htmlEscape = escape

const UNESCAPE_ENTITIES = Object.keys(ENTITIES).reduce((map, key) => {
  const value = ENTITIES[key]
  map[value] = key
  return map
}, {})

const unescapeSource = `(?:${Object.keys(UNESCAPE_ENTITIES).join('|')})`
const UNESCAPE_REGEX = new RegExp(unescapeSource, 'g')

/**
 * @param {string} str - The string with HTML entities to be unescaped.
 * @returns {string} The unescaped string with HTML entities converted back to characters.
 *
 * @example
 * // Example of unescaping a string with HTML entities
 * const escapedString = "&lt;script&gt;alert('XSS')&lt;/script&gt;";
 * const unescapedString = unescape(escapedString);
 * // unescapedString would be: "<script>alert('XSS')</script>"
 */
export function unescape(str) {
  return str.replace(UNESCAPE_REGEX, match => UNESCAPE_ENTITIES[match])
}

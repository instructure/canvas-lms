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

// This does what jQuery's .param() does, only without having to bring in all
// of jQuery.

// URLSearchParams turns arrays into queries like   a=1,2,3
// But our jQuery makes the older "PHP" style like  a[]=1&a[]=2&a[]=3
// JQuery also magically deals with parameters that are functions, and recursive
// objects within objects, {a: 1, b: {c: 2, d: 3}, e: 4} => a=1&b[c]=2&b[d]=3&e=4
// ... so we have to do a lot of massaging with the params object before using it
// So fun!

type QueryParameterElement =
  | string
  | number
  | boolean
  | null
  | undefined
  | (() => string) // n.b. for jQuery compatibility, this does not expect a generic return
  | Array<QueryParameterElement>
  | QueryParameterMap

export type QueryParameterMap = {[k: string]: QueryParameterElement}

export default function toQueryString(params: QueryParameterMap): string {
  const paramsWithIndexes: Array<[k: string, v: string]> = []

  // fix up the array/object indexes to match the PHP standard
  function fixIndexes(elt: [string, string]): [string, string] {
    return [
      elt[0]
        .replace(/\[\d+\]$/, '[]')
        .replace(/{/g, '[')
        .replace(/}/g, ']'),
      elt[1],
    ]
  }

  function serialize(k: string, elt: QueryParameterElement, suffix: string): void {
    if (elt instanceof Function) {
      paramsWithIndexes.push([k + suffix, elt()])
    } else if (elt instanceof Array) {
      for (const k2 in elt) {
        serialize(k, elt[k2], `${suffix}[${k2}]`)
      }
    } else if (elt instanceof Object) {
      for (const k2 in elt) {
        serialize(k, elt[k2], `${suffix}{${k2}}`)
      }
    } else if (typeof elt === 'boolean' || typeof elt === 'number') {
      paramsWithIndexes.push([k + suffix, elt.toString()])
    } else if (typeof elt === 'undefined') {
      paramsWithIndexes.push([k + suffix, 'undefined'])
    } else if (elt === null) {
      paramsWithIndexes.push([k + suffix, 'null'])
    } else if (typeof elt === 'string') {
      paramsWithIndexes.push([k + suffix, elt])
    }
  }

  for (const k in params) serialize(k, params[k], '')

  return new URLSearchParams(paramsWithIndexes.map(fixIndexes)).toString()
}

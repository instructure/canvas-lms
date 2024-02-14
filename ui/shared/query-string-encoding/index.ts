/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

// toQueryString does what jQuery's .param() does, only without having to bring in
// all of jQuery.

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
  | QueryParameterRecord

export type QueryParameterRecord = {[k: string]: QueryParameterElement}

export function toQueryString(params: QueryParameterRecord): string {
  const paramsWithIndexes: Array<[k: string, v: string]> = []

  // fix up the array/object indexes to match the PHP standard
  const fixIndexes = (elt: [string, string]): [string, string] => [
    elt[0]
      .replace(/\[\d+\]$/, '[]')
      .replace(/{/g, '[')
      .replace(/}/g, ']'),
    elt[1],
  ]

  function serialize(k: string, elt: QueryParameterElement, suffix: string): void {
    if (elt instanceof Function) {
      paramsWithIndexes.push([k + suffix, elt()])
    } else if (elt instanceof Array) {
      elt.forEach((k2, i) => serialize(k, k2, `${suffix}[${i}]`))
    } else if (elt instanceof Object) {
      Object.keys(elt).forEach(k2 => serialize(k, elt[k2], `${suffix}{${k2}}`))
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

  Object.keys(params).forEach(k => serialize(k, params[k], ''))
  return new URLSearchParams(paramsWithIndexes.map(fixIndexes)).toString()
}

// This is just to implement backward-compatibility from the old package. Almost
// nothing uses it anyway and we recommend toQueryString() for new needs.
// Need to be careful about duplicated keys, which have to be mapped into arrays.
export function encodeQueryString(
  unknownParams:
    | Record<string, string | null | undefined>[]
    | Record<string, string | null | undefined>
): string {
  let params: Record<string, string | null | undefined>[]

  if (Array.isArray(unknownParams)) {
    params = unknownParams
  } else if (typeof unknownParams === 'object') {
    params = [unknownParams as Record<string, string | null | undefined>]
  } else {
    throw new TypeError('encodeQueryString() expects an array or object')
  }

  const realParms: QueryParameterRecord = {}
  params.forEach(p => {
    const k = Object.keys(p)[0]
    const m = k.match(/(.+)\[\]/)
    if (p[k] === null) return
    if (m === null) {
      // Not building up an array, just jam this in there, unless it's already
      // in there and IS already an array.
      if (Array.isArray(realParms[k])) throw new TypeError('cannot mix scalar and array parameters')
      Object.assign(realParms, p)
    } else {
      // We ARE building up an array... append this value to an existing array
      // if it exists, otherwise create one. If an existing key already exists
      // and is NOT an array, then this is an error
      const idx = m[1]
      let arrayParm = realParms[idx]
      if (typeof arrayParm === 'undefined') arrayParm = []
      if (!Array.isArray(arrayParm)) throw new TypeError('cannot mix scalar and array parameters')
      arrayParm.push(p[k])
      realParms[idx] = arrayParm
    }
  })
  return toQueryString(realParms)
}

// TODO: should be an inverse of toQueryString that takes a string and returns a
// QueryParameterRecord. The result would be slightly different from decodeQueryString
// in terms of how things like  foo[]=1&foo[]=2  would be decoded. But it doesn't
// seem like any current usage cares about that kind of thing.

export function decodeQueryString(string: string) {
  return string
    .split('&')
    .map(pair => pair.split('='))
    .map(([key, value]) => ({[key]: value}))
}

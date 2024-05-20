/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {toQueryString, encodeQueryString, decodeQueryString} from '../index'
import type {QueryParameterRecord} from '../index'
import $ from 'jquery'

type EncodeQueryStringParams = Array<Record<string, string | null>>

const func = () => 'result'
const func2 = () => 'yet another result'

const EX: {[k: string]: QueryParameterRecord} = {
  empty: {},
  scalars_with_numbers_strings_and_bools: {frd: 1, str: 'syzygy', butNo: false},
  // null and undefined behavior was congruent with jquery 1.7,
  // but no longer with 1.8
  // cf. https://bugs.jquery.com/ticket/8653/
  // scalars_with_null: {frd: 1, butNo: null},
  // scalars_with_undefined: {frd: 1, butNo: undefined, last: 'zzz'},
  scalars_with_functions: {frd: 1, func, func2},
  simple_array: {blah: [1, 2, 3]},
  mixed_types_array: {blah: [1, 'b', 'III']},
  recursive_object: {blah: 1, sub: {one: 1, two: [2, 4]}, last: 'zzz'},
  array_of_objects: {
    blah: [
      {one: 1, two: 2},
      {one: '1', two: '2'},
    ],
  },
  object_with_arrays: {blah: {one: [1, 2, 3], two: [2, 4, 6]}},
}

describe('toQueryString::', () => {
  describe('does everything jQuery does', () => {
    for (const ex in EX) {
      it(`handles example ${ex}`, () => {
        const subject = EX[ex]
        const testResult = toQueryString(subject)
        // jQuery's $.param() function changed its encoding behavior from replacing spaces with '+'
        // to using '%20' between versions 2.2.4 and 3.x. This change aligns with the standard URI
        // encoding conventions specified by the W3C. We're temporarily patching this in the test
        // until we update the code to adhere to the standard URI encoding conventions.
        const jQueryResult = $.param(subject).replace(/%20/g, '+')
        expect(testResult).toBe(jQueryResult)
      })
    }
  })
})

describe('encodeQueryString::', () => {
  it('encodes a query string from array of params', () => {
    const params: EncodeQueryStringParams = [{foo: 'bar'}, {hello: 'world'}]
    const query = encodeQueryString(params)
    expect(query).toBe('foo=bar&hello=world')
  })

  it('encodes a query string from array of params with duplicate keys', () => {
    const params: EncodeQueryStringParams = [{'foo[]': 'bar'}, {'foo[]': 'world'}]
    const query = encodeQueryString(params)
    expect(query).toBe('foo%5B%5D=bar&foo%5B%5D=world')
  })

  it('won’t pass along any null values for some reason', () => {
    const params: EncodeQueryStringParams = [{foo: '256'}, {hello: null}, {baz: '512'}]
    const query = encodeQueryString(params)
    expect(query).toBe('foo=256&baz=512')
  })

  it('throws TypeError if we try to turn a non-array param into an array param', () => {
    const params: EncodeQueryStringParams = [{foo: 'bar'}, {'foo[]': 'world'}]
    expect(() => encodeQueryString(params)).toThrow(TypeError)
  })

  it('throws TypeError if we try to turn an array param into a non-array param', () => {
    const params: EncodeQueryStringParams = [{'foo[]': 'bar'}, {foo: 'world'}]
    expect(() => encodeQueryString(params)).toThrow(TypeError)
  })
})

describe('decodeQueryString::', () => {
  it('decodes a query string into an array of params', () => {
    const params = decodeQueryString('foo=bar&hello=world')
    expect(params).toMatchObject([{foo: 'bar'}, {hello: 'world'}])
  })

  it('decodes a query string with duplicate keys into an array of params', () => {
    const params = decodeQueryString('foo[]=bar&foo[]=world')
    expect(params).toMatchObject([{'foo[]': 'bar'}, {'foo[]': 'world'}])
  })
})

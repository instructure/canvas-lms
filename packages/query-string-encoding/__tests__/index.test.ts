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
import type {QueryParameterRecord} from '../index.d'
import $ from 'jquery'

type EncodeQueryStringParams = Array<Record<string, string | null>>

// pulling this out for better readability of the test case enumerations below
const BIG_OBJECT = {
  A225: 'Antonov An-225 Mriya',
  B2: 'Northrop B2 Spirit',
  B36T: 'Beechcraft B36 Turbo Bonanza',
  B58T: 'Beechcraft Turbo Baron',
  B779: 'Boeing 777-9',
  B788: 'Boeing 787 Dreamliner',
  C152: 'Cessna 152 Aerobat',
  C172: 'Cessna 172 Skyhawk',
  C182: 'Cessna 182 Skylane',
  C210: 'Cessna 210 Centurion',
  C337: 'Cessna 337 Skymaster',
  C97: 'Boeing C-97 Stratofreighter',
  C402: 'Cessna 402 Businessliner',
  DA40: 'Diamond DA40 Diamondstar',
  DA42: 'Diamond DA42 Twinstar',
  DC10: 'McDonnell-Douglas DC-10',
  F117: 'Lockheed F-117 Nighthawk',
  F14: 'Grumman F-14 Tomcat',
  P28A: 'Piper PA-28 Cherokee Archer',
  P28R: 'Piper PA-28 Cherokee Arrow',
  P32R: 'Piper PA-32 Saratoga SP',
  PA38: 'Piper PA-38 Tomahawk',
  SF50: 'Cirrus SF50 Vision Jet',
  SR20: 'Cirrus SR20',
  SR22: 'Cirrus SR22',
}

const func = () => 'result'
const func2 = () => 'yet another result'

const EX: {[k: string]: QueryParameterRecord} = {
  empty: {},
  empty_strings: {foo: '', bar: ''},
  crazy_uri_characters: {query: 'a+b=c&d=e so there!'},
  scalars_with_numbers_strings_and_bools: {frd: 1, str: 'syzygy', butNo: false},
  scalars_with_null: {frd: 1, butNo: null},
  scalars_with_undefined: {frd: 1, butNo: undefined, last: 'zzz'},
  scalars_with_functions: {frd: 1, func, func2},
  big_objects: BIG_OBJECT,
  multiply_nested_objects: {level1: {level2: {level3: 'so-deep'}}},
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
        const jQueryResult = $.param(subject)
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

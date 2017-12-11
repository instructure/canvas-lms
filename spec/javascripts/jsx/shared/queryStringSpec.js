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

import { encodeQueryString, decodeQueryString } from 'jsx/shared/queryString'

QUnit.module('Query String util')

QUnit.module('encodeQueryString')

test('encodes a query string from array of params', () => {
  const params = [{ foo: 'bar' }, { hello: 'world' }]
  const query = encodeQueryString(params)
  equal(query, 'foo=bar&hello=world')
})

test('encodes a query string from array of params with duplicate keys', () => {
  const params = [{ 'foo[]': 'bar' }, { 'foo[]': 'world' }]
  const query = encodeQueryString(params)
  equal(query, 'foo[]=bar&foo[]=world')
})

QUnit.module('decodeQueryString')

test('decodes a query string into an array of params', () => {
  const params = decodeQueryString('foo=bar&hello=world')
  deepEqual(params, [{ foo: 'bar' }, { hello: 'world' }])
})

test('decodes a query string with duplicate keys into an array of params', () => {
  const params = decodeQueryString('foo[]=bar&foo[]=world')
  deepEqual(params, [{ 'foo[]': 'bar' }, { 'foo[]': 'world' }])
})
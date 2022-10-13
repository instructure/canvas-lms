/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import Helpers from '@canvas/util/searchHelpers'

QUnit.module('searchHelpers#exactMatchRegex', {
  setup() {
    this.regex = Helpers.exactMatchRegex('hello!')
  },
})

test('tests true against an exact match', function () {
  equal(this.regex.test('hello!'), true)
})

test('ignores case', function () {
  equal(this.regex.test('Hello!'), true)
})

test('tests false if it is a substring', function () {
  equal(this.regex.test('hello!sir'), false)
})

test('tests false against a completely different string', function () {
  equal(this.regex.test('cat'), false)
})

QUnit.module('searchHelpers#startOfStringRegex', {
  setup() {
    this.regex = Helpers.startOfStringRegex('hello!')
  },
})

test('tests true against an exact match', function () {
  equal(this.regex.test('hello!'), true)
})

test('ignores case', function () {
  equal(this.regex.test('Hello!'), true)
})

test('tests false if it is a substring that does not start at the beggining of the test string', function () {
  equal(this.regex.test('bhello!sir'), false)
})

test('tests true if it is a substring that starts at the beggining of the test string', function () {
  equal(this.regex.test('hello!sir'), true)
})

test('tests false against a completely different string', function () {
  equal(this.regex.test('cat'), false)
})

QUnit.module('searchHelpers#substringMatchRegex', {
  setup() {
    this.regex = Helpers.substringMatchRegex('hello!')
  },
})

test('tests true against an exact match', function () {
  equal(this.regex.test('hello!'), true)
})

test('ignores case', function () {
  equal(this.regex.test('Hello!'), true)
})

test('tests true if it is a substring that does not start at the beggining of the test string', function () {
  equal(this.regex.test('bhello!sir'), true)
})

test('tests true if it is a substring that starts at the beggining of the test string', function () {
  equal(this.regex.test('hello!sir'), true)
})

test('tests false against a completely different string', function () {
  equal(this.regex.test('cat'), false)
})

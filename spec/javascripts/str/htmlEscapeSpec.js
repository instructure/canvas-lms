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

import htmlEscape from 'str/htmlEscape'

const {unescape} = htmlEscape

QUnit.module('htmlEscape', () => {
  QUnit.module('.htmlEscape()', () => {
    test('replaces "&" with "&amp;"', () => {
      equal(htmlEscape('foo & bar'), 'foo &amp; bar')
    })

    test('replaces "<" with "&lt;"', () => {
      equal(htmlEscape('foo < bar'), 'foo &lt; bar')
    })

    test('replaces ">" with "&gt;"', () => {
      equal(htmlEscape('foo > bar'), 'foo &gt; bar')
    })

    test('replaces " with "&quot;"', () => {
      equal(htmlEscape('foo " bar'), 'foo &quot; bar')
    })

    test('replaces \' with "&#x27;"', () => {
      equal(htmlEscape("foo ' bar"), 'foo &#x27; bar')
    })

    test('replaces "/" with "&#x2F;"', () => {
      equal(htmlEscape('foo / bar'), 'foo &#x2F; bar')
    })

    test('replaces "`" with "&#x60;"', () => {
      equal(htmlEscape('foo ` bar'), 'foo &#x60; bar')
    })

    test('replaces "=" with "&#x3D;"', () => {
      equal(htmlEscape('foo = bar'), 'foo &#x3D; bar')
    })

    test('replaces any combination of known replaceable values', () => {
      const value = '& < > " \' / ` ='
      equal(htmlEscape(value), '&amp; &lt; &gt; &quot; &#x27; &#x2F; &#x60; &#x3D;')
    })
  })

  QUnit.module('.unescape()', () => {
    test('replaces "&amp;" with "&"', () => {
      equal(unescape('foo &amp; bar'), 'foo & bar')
    })

    test('replaces "&lt;" with "<"', () => {
      equal(unescape('foo &lt; bar'), 'foo < bar')
    })

    test('replaces "&gt;" with ">"', () => {
      equal(unescape('foo &gt; bar'), 'foo > bar')
    })

    test('replaces "&quot;" with "', () => {
      equal(unescape('foo &quot; bar'), 'foo " bar')
    })

    test('replaces "&#x27;" with \'', () => {
      equal(unescape('foo &#x27; bar'), "foo ' bar")
    })

    test('replaces "&#x2F;" with "/"', () => {
      equal(unescape('foo &#x2F; bar'), 'foo / bar')
    })

    test('replaces "&#x60;" with "`"', () => {
      equal(unescape('foo &#x60; bar'), 'foo ` bar')
    })

    test('replaces "&#x3D;" with "="', () => {
      equal(unescape('foo &#x3D; bar'), 'foo = bar')
    })

    test('replaces any combination of known replaceable values', () => {
      const value = '&amp; &lt; &gt; &quot; &#x27; &#x2F; &#x60; &#x3D;'
      equal(unescape(value), '& < > " \' / ` =')
    })
  })
})

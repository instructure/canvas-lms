/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import * as TextHelper from '../TextHelper'

describe('formatMessage', () => {
  test('detects and linkify URLs', () => {
    const testNode = document.createElement('div')
    let link: HTMLAnchorElement
    let str: string
    str = TextHelper.formatMessage(
      'click here: (http://www.instructure.com) to check things out\nnewline'
    )
    testNode.innerHTML = str
    link = testNode.getElementsByTagName('a')[0]
    expect(link.href).toBe('http://www.instructure.com/')

    str = TextHelper.formatMessage('click here: http://www.instructure.com\nnewline')
    testNode.innerHTML = str
    link = testNode.getElementsByTagName('a')[0]
    expect(link.href).toBe('http://www.instructure.com/')

    str = TextHelper.formatMessage('click here: www.instructure.com/a/b?a=1&b=2\nnewline')
    testNode.innerHTML = str
    link = testNode.getElementsByTagName('a')[0]
    expect(link.href).toBe('http://www.instructure.com/a/b?a=1&b=2')

    str = TextHelper.formatMessage('click here: http://www.instructure.com/\nnewline')
    testNode.innerHTML = str
    link = testNode.getElementsByTagName('a')[0]
    expect(link.href).toBe('http://www.instructure.com/')

    str = TextHelper.formatMessage(
      'click here: http://www.instructure.com/courses/1/pages/informação'
    )
    testNode.innerHTML = str
    link = testNode.getElementsByTagName('a')[0]
    expect(link.href).toBe('http://www.instructure.com/courses/1/pages/informa%C3%A7%C3%A3o')

    str = TextHelper.formatMessage('click here: http://www.instructure.com/courses/1/pages#anchor')
    testNode.innerHTML = str
    link = testNode.getElementsByTagName('a')[0]
    expect(link.href).toBe('http://www.instructure.com/courses/1/pages#anchor')

    str = TextHelper.formatMessage(
      "click here: http://www.instructure.com/'onclick=alert(document.cookie)//\nnewline"
    )
    testNode.innerHTML = str
    link = testNode.getElementsByTagName('a')[0]
    expect(link.href).toBe("http://www.instructure.com/'onclick=alert(document.cookie)//")

    // > ~15 chars in parens used to blow up the parser to take forever
    str = TextHelper.formatMessage(
      'click here: http://www.instructure.com/(012345678901234567890123456789012345678901234567890)'
    )
    testNode.innerHTML = str
    link = testNode.getElementsByTagName('a')[0]
    expect(link.href).toBe(
      'http://www.instructure.com/(012345678901234567890123456789012345678901234567890)'
    )
  })

  test('handles having the placeholder in the text body', () => {
    const str = TextHelper.formatMessage(
      `this text has the placeholder ${TextHelper.AUTO_LINKIFY_PLACEHOLDER} embedded right in it.\nhttp://www.instructure.com/\n`
    )
    expect(str).toBe(
      `this text has the placeholder ${TextHelper.AUTO_LINKIFY_PLACEHOLDER} embedded right in it.<br />\n<a href='http:&#x2F;&#x2F;www.instructure.com&#x2F;'>http:&#x2F;&#x2F;www.instructure.com&#x2F;</a><br />\n`
    )
  })
})

describe('delimit', () => {
  test('comma-delimits long numbers', () => {
    expect(TextHelper.delimit(123456)).toBe('123,456')
    expect(TextHelper.delimit(9999999)).toBe('9,999,999')
    expect(TextHelper.delimit(-123456)).toBe('-123,456')
    expect(TextHelper.delimit(123456)).toBe('123,456')
  })

  test('comma-delimits integer portion only of decimal numbers', () => {
    expect(TextHelper.delimit(123456.12521)).toBe('123,456.12521')
    expect(TextHelper.delimit(9999999.99999)).toBe('9,999,999.99999')
  })

  test('does not comma-delimit short numbers', () => {
    expect(TextHelper.delimit(123)).toBe('123')
    expect(TextHelper.delimit(0)).toBe('0')
  })

  test('should not error on NaN', () => {
    expect(TextHelper.delimit(0 / 0)).toBe('NaN')
    expect(TextHelper.delimit(5 / 0)).toBe('Infinity')
    expect(TextHelper.delimit(-5 / 0)).toBe('-Infinity')
  })
})

describe('truncateText', () => {
  test('should work in the basic case', () => {
    expect(TextHelper.truncateText('this is longer than 30 characters')).toBe(
      'this is longer than 30...'
    )
  })

  test('should truncate on word boundaries without exceeding max', () => {
    expect(TextHelper.truncateText('zomg zomg zomg', {max: 11})).toBe('zomg...')
    expect(TextHelper.truncateText('zomg zomg zomg', {max: 12})).toBe('zomg zomg...')
    expect(TextHelper.truncateText('zomg zomg zomg', {max: 13})).toBe('zomg zomg...')
    expect(TextHelper.truncateText('zomg      whitespace!   ', {max: 15})).toBe('zomg...')
  })

  test('should not truncate if the string fits', () => {
    expect(TextHelper.truncateText('zomg zomg zomg', {max: 14})).toBe('zomg zomg zomg')
    expect(TextHelper.truncateText('zomg      whitespace!   ', {max: 16})).toBe('zomg whitespace!')
  })

  test('should break up the first word if it exceeds max', () => {
    expect(TextHelper.truncateText('zomgzomg', {max: 6})).toBe('zom...')
    expect(TextHelper.truncateText('zomgzomg', {max: 7})).toBe('zomg...')
  })
})

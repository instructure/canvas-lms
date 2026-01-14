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
import fc from 'fast-check'

describe('formatMessage', () => {
  test('detects and linkify URLs', () => {
    const testNode = document.createElement('div')
    let link: HTMLAnchorElement
    let str: string
    str = TextHelper.formatMessage(
      'click here: (http://www.instructure.com) to check things out\nnewline',
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
      'click here: http://www.instructure.com/courses/1/pages/informação',
    )
    testNode.innerHTML = str
    link = testNode.getElementsByTagName('a')[0]
    expect(link.href).toBe('http://www.instructure.com/courses/1/pages/informa%C3%A7%C3%A3o')

    str = TextHelper.formatMessage('click here: http://www.instructure.com/courses/1/pages#anchor')
    testNode.innerHTML = str
    link = testNode.getElementsByTagName('a')[0]
    expect(link.href).toBe('http://www.instructure.com/courses/1/pages#anchor')

    str = TextHelper.formatMessage(
      "click here: http://www.instructure.com/'onclick=alert(document.cookie)//\nnewline",
    )
    testNode.innerHTML = str
    link = testNode.getElementsByTagName('a')[0]
    expect(link.href).toBe("http://www.instructure.com/'onclick=alert(document.cookie)//")

    // > ~15 chars in parens used to blow up the parser to take forever
    str = TextHelper.formatMessage(
      'click here: http://www.instructure.com/(012345678901234567890123456789012345678901234567890)',
    )
    testNode.innerHTML = str
    link = testNode.getElementsByTagName('a')[0]
    expect(link.href).toBe(
      'http://www.instructure.com/(012345678901234567890123456789012345678901234567890)',
    )
  })

  test('handles having the placeholder in the text body', () => {
    const str = TextHelper.formatMessage(
      `this text has the placeholder ${TextHelper.AUTO_LINKIFY_PLACEHOLDER} embedded right in it.\nhttp://www.instructure.com/\n`,
    )
    expect(str).toBe(
      `this text has the placeholder ${TextHelper.AUTO_LINKIFY_PLACEHOLDER} embedded right in it.<br />\n<a href='http:&#x2F;&#x2F;www.instructure.com&#x2F;'>http:&#x2F;&#x2F;www.instructure.com&#x2F;</a><br />\n`,
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
      'this is longer than 30...',
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

describe('containsHtmlTags', () => {
  test('should return true if html tags present', () => {
    expect(TextHelper.containsHtmlTags('<p>Html detected</p>')).toBeTruthy()
  })

  test('should return false if not present', () => {
    expect(TextHelper.containsHtmlTags('No html present')).toBeFalsy()
  })
})

describe('stripHtmlTags', () => {
  const htmlText = '<p>Test <strong>Content</strong></p>'
  const strippedText = 'Test Content'

  it('returns stripped text if arg is HTML text', () => {
    const result = TextHelper.stripHtmlTags(htmlText)
    expect(result).toEqual(strippedText)
  })

  it('returns empty string if arg is empty', () => {
    const result = TextHelper.stripHtmlTags('')
    expect(result).toEqual('')
  })

  it('returns empty string if undefined provided', () => {
    const result = TextHelper.stripHtmlTags()
    expect(result).toEqual('')
  })

  test('decodes HTML entities to their character equivalents', () => {
    expect(TextHelper.stripHtmlTags('&quot;')).toBe('"')
    expect(TextHelper.stripHtmlTags('&amp;')).toBe('&')
    expect(TextHelper.stripHtmlTags('&lt;')).toBe('<')
    expect(TextHelper.stripHtmlTags('&gt;')).toBe('>')
  })

  test('handles complex names with multiple HTML entities', () => {
    expect(TextHelper.stripHtmlTags('John Fields j&quot;E&amp;D&lt;I&gt;')).toBe(
      'John Fields j"E&D<I>',
    )
  })

  test('handles names without HTML entities', () => {
    expect(TextHelper.stripHtmlTags('John Doe')).toBe('John Doe')
  })

  test('handles mixed text with some HTML entities', () => {
    expect(TextHelper.stripHtmlTags('Hello &amp; welcome to &lt;Canvas&gt;!')).toBe(
      'Hello & welcome to <Canvas>!',
    )
  })
})

describe('htmlDecode', () => {
  test('should return the same result when decoding twice', () => {
    fc.assert(
      fc.property(fc.string(), input => {
        const once = TextHelper.htmlDecode(input)
        const twice = TextHelper.htmlDecode(once)
        expect(once).toBe(twice)
      }),
    )
  })

  test.each([
    ['empty string', ''],
    ['undefined', undefined],
    ['null', null],
  ])('should return empty string for %s input', (_, input) => {
    expect(TextHelper.htmlDecode(input)).toBe('')
  })

  test.each([
    ['&amp;', '&', 'ampersand'],
    ['&lt;', '<', 'less than'],
    ['&gt;', '>', 'greater than'],
    ['&quot;', '"', 'quotation mark'],
    ['&#x27;', "'", 'apostrophe'],
  ])('decodes %s (%s)', (input, expected) => {
    expect(TextHelper.htmlDecode(input)).toBe(expected)
  })

  test('decodes numeric entities', () => {
    expect(TextHelper.htmlDecode('&#65;')).toBe('A')
    expect(TextHelper.htmlDecode('&#8364;')).toBe('€')
  })

  test('strips simple HTML tags', () => {
    expect(TextHelper.htmlDecode('<p>Hello</p>')).toBe('Hello')
    expect(TextHelper.htmlDecode('<div><strong>Bold</strong> text</div>')).toBe('Bold text')
  })

  test('handles self-closing tags', () => {
    expect(TextHelper.htmlDecode('Line 1<br/>Line 2')).toBe('Line 1Line 2')
  })

  test('handles simple mixed tags and entities', () => {
    expect(TextHelper.htmlDecode('<p>Hello &amp; goodbye</p>')).toBe('Hello & goodbye')
  })

  test('handles complex mixed tags and entities', () => {
    expect(TextHelper.htmlDecode('<b>User: &quot;John&quot; &lt;john@test.com&gt;</b>')).toBe(
      'User: "John" <john@test.com>',
    )
  })

  test.each([
    ['Caf&eacute;', 'Café', 'accented e'],
    ['&copy; 2023', '© 2023', 'copyright symbol'],
    ['&nbsp;', '\u00A0', 'non-breaking space'],
    ['Smith &amp; Johnson', 'Smith & Johnson', 'ampersand in name'],
  ])('decodes %s (%s)', (input, expected) => {
    expect(TextHelper.htmlDecode(input)).toBe(expected)
  })

  test.each([
    ['Jos&eacute; Mart&iacute;nez', 'José Martínez', 'Spanish accents'],
    ['Fran&ccedil;ois Dubois', 'François Dubois', 'French cedilla'],
    ['O&apos;Connor', "O'Connor", 'Irish apostrophe'],
    ['M&uuml;ller', 'Müller', 'German umlaut'],
    ['&Aring;se Larsson', 'Åse Larsson', 'Scandinavian ring'],
    ['&Ntilde;u&ntilde;ez', 'Ñuñez', 'Spanish tildes'],
  ])('decodes international name %s (%s)', (input, expected) => {
    expect(TextHelper.htmlDecode(input)).toBe(expected)
  })

  test('handles emails with encoded characters', () => {
    expect(TextHelper.htmlDecode('some&apos;email@gmail.com')).toBe("some'email@gmail.com")
  })

  test('does not transform unencoded emails', () => {
    expect(TextHelper.htmlDecode("user+tes't@example.com")).toBe("user+tes't@example.com")
  })

  test('handles whitespace-only input', () => {
    expect(TextHelper.htmlDecode('   ')).toBe('   ')
  })

  test('decodes entities with trailing whitespace', () => {
    expect(TextHelper.htmlDecode('&lt;Test&gt;  ')).toBe('<Test>  ')
  })

  test('decodes entities with leading whitespace', () => {
    expect(TextHelper.htmlDecode('  A&amp;Test')).toBe('A&Test')
  })

  test('handles malformed HTML', () => {
    expect(TextHelper.htmlDecode('<div>Unclosed')).toBe('Unclosed')
  })

  test('returns unchanged text with no HTML entities or tags', () => {
    const input = 'Normal text without HTML'
    expect(TextHelper.htmlDecode(input)).toBe(input)
  })
})

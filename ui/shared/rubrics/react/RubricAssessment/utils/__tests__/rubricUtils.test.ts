/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {escapeNewLineText, fullyDecodeHtmlEntities, decodeHtmlEntities} from '../rubricUtils'

describe('escapeNewLineText', () => {
  it('escapes HTML and replaces newlines', () => {
    const result = escapeNewLineText('<div>hello</div>')
    expect(result.__html).toBe('&lt;div&gt;hello&lt;&#x2F;div&gt;')
  })

  it('escapes special characters', () => {
    const result = escapeNewLineText('& < > " \'')
    expect(result.__html).toBe('&amp; &lt; &gt; &quot; &#x27;')
  })

  it('replaces newlines with <br /> tags', () => {
    const result = escapeNewLineText('line1\nline2\nline3')
    expect(result.__html).toBe('line1<br />line2<br />line3')
  })

  it('escapes HTML and replaces newlines together', () => {
    const result = escapeNewLineText('<div>hello</div>\n<p>world</p>')
    expect(result.__html).toBe(
      '&lt;div&gt;hello&lt;&#x2F;div&gt;<br />&lt;p&gt;world&lt;&#x2F;p&gt;',
    )
  })

  it('handles empty string', () => {
    const result = escapeNewLineText('')
    expect(result.__html).toBe('')
  })

  it('handles undefined', () => {
    const result = escapeNewLineText(undefined)
    expect(result.__html).toBe('')
  })
})

describe('decodeHtmlEntities', () => {
  it('decodes HTML entities', () => {
    const result = decodeHtmlEntities('&lt;div&gt;hello&lt;/div&gt;')
    expect(result).toBe('<div>hello</div>')
  })

  it('decodes common HTML entities', () => {
    const result = decodeHtmlEntities('&amp; &lt; &gt; &quot; &#39;')
    expect(result).toBe('& < > " \'')
  })

  it('handles empty string', () => {
    const result = decodeHtmlEntities('')
    expect(result).toBe('')
  })

  it('handles undefined', () => {
    const result = decodeHtmlEntities(undefined)
    expect(result).toBe('')
  })

  it('preserves already-decoded text', () => {
    const result = decodeHtmlEntities('<div>hello</div>')
    expect(result).toBe('<div>hello</div>')
  })
})

describe('fullyDecodeHtmlEntities', () => {
  it('decodes double-encoded HTML entities', () => {
    const result = fullyDecodeHtmlEntities('&amp;lt;div&amp;gt;hello&amp;lt;/div&amp;gt;')
    expect(result).toBe('<div>hello</div>')
  })

  it('decodes triple-encoded HTML entities', () => {
    const result = fullyDecodeHtmlEntities('&amp;amp;lt;div&amp;amp;gt;')
    expect(result).toBe('<div>')
  })

  it('handles single encoding', () => {
    const result = fullyDecodeHtmlEntities('&lt;div&gt;hello&lt;/div&gt;')
    expect(result).toBe('<div>hello</div>')
  })

  it('handles empty string', () => {
    const result = fullyDecodeHtmlEntities('')
    expect(result).toBe('')
  })

  it('handles undefined', () => {
    const result = fullyDecodeHtmlEntities(undefined)
    expect(result).toBe('')
  })

  it('preserves already-decoded text', () => {
    const result = fullyDecodeHtmlEntities('<div>hello</div>')
    expect(result).toBe('<div>hello</div>')
  })

  it('handles text with no entities', () => {
    const result = fullyDecodeHtmlEntities('plain text')
    expect(result).toBe('plain text')
  })
})

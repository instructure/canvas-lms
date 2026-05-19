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

import {decodeHTML, formatLongDescriptionHTML} from '../index'

describe('decodeHTML', () => {
  it('returns plain text unchanged', () => {
    expect(decodeHTML('hello world')).toBe('hello world')
  })

  it('decodes &#39; (Ruby html_escape apostrophe)', () => {
    expect(decodeHTML('that&#39;s that')).toBe("that's that")
  })

  it('decodes &#x27; (@instructure/html-escape apostrophe)', () => {
    expect(decodeHTML('that&#x27;s that')).toBe("that's that")
  })

  it('decodes &amp;', () => {
    expect(decodeHTML('rock &amp; roll')).toBe('rock & roll')
  })

  it('decodes &lt; and &gt;', () => {
    expect(decodeHTML('&lt;div&gt;')).toBe('<div>')
  })

  it('decodes &quot;', () => {
    expect(decodeHTML('say &quot;hello&quot;')).toBe('say "hello"')
  })

  it('handles empty string', () => {
    expect(decodeHTML('')).toBe('')
  })

  it('decodes multiple entities in one string', () => {
    expect(decodeHTML('&lt;b&gt;that&#39;s &amp; this&lt;/b&gt;')).toBe("<b>that's & this</b>")
  })
})

describe('formatLongDescriptionHTML', () => {
  it('returns empty string for empty input', () => {
    expect(formatLongDescriptionHTML('')).toBe('')
  })

  it('returns plain text with no special characters unchanged', () => {
    expect(formatLongDescriptionHTML('hello world')).toBe('hello world')
  })

  it('decodes &#39; from Ruby backend and re-encodes safely', () => {
    // &#39; (Ruby) → ' → &#x27; (@instructure/html-escape) — both render as ' in the browser
    expect(formatLongDescriptionHTML('that&#39;s that')).toBe('that&#x27;s that')
  })

  it('converts <br/> to <br /> for line break rendering', () => {
    expect(formatLongDescriptionHTML('line1<br/>line2')).toBe('line1<br />line2')
  })

  it('converts \\n to <br /> for line break rendering', () => {
    expect(formatLongDescriptionHTML('line1\nline2')).toBe('line1<br />line2')
  })

  it('handles a mix of <br/> and \\n', () => {
    expect(formatLongDescriptionHTML('line1<br/>line2\nline3')).toBe('line1<br />line2<br />line3')
  })

  it('escapes XSS from backend-escaped HTML', () => {
    // Backend stores &lt;script&gt; — decodeHTML turns it to <script>, htmlEscape re-encodes it
    // Note: htmlEscape also encodes / as &#x2F; for additional XSS protection
    const result = formatLongDescriptionHTML('&lt;script&gt;alert(1)&lt;/script&gt;')
    expect(result).toBe('&lt;script&gt;alert(1)&lt;&#x2F;script&gt;')
  })

  it('escapes ampersands', () => {
    expect(formatLongDescriptionHTML('rock &amp; roll')).toBe('rock &amp; roll')
  })
})

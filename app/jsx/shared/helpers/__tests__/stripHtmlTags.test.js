/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {stripHtmlTags} from '../stripHtmlTags'

describe('stripHtmlTags', () => {
  const htmlText = '<p>Test <strong>Content</strong></p>'
  const strippedText = 'Test Content'

  it('returns stripped text if arg is HTML text', () => {
    const result = stripHtmlTags(htmlText)
    expect(result).toEqual(strippedText)
  })

  it('returns empty string if arg is empty', () => {
    const result = stripHtmlTags('')
    expect(result).toEqual('')
  })

  it('returns empty string if no arg provided', () => {
    const result = stripHtmlTags()
    expect(result).toEqual('')
  })
})

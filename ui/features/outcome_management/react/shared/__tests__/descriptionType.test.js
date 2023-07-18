/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import descriptionType from '../descriptionType'

describe('descriptionType', () => {
  it('should return "null" if description is empty', () => {
    const result = descriptionType('')
    expect(result).toBe('null')
  })

  it('should return "text" if description contains only plain text', () => {
    const result = descriptionType('This is a plain text description.')
    expect(result).toBe('text')
  })

  it('should return "html_text" if description contains only one <p> or <div> tag with text content', () => {
    const resultWithPTag = descriptionType('<p>This is an HTML text description.</p>')
    const resultWithDivTag = descriptionType('<div>This is another HTML text description.</div>')
    expect(resultWithPTag).toBe('html_text')
    expect(resultWithDivTag).toBe('html_text')
  })

  it('should return "html" if description contains HTML content other than one <p> or <div> tag', () => {
    const result = descriptionType('<div><p>This is an HTML description with tags.</p></div>')
    expect(result).toBe('html')
  })

  it('returns "html" value for HTML formatted description', () => {
    const result = descriptionType('<p>Outcome <strong>Description</strong></p>')
    expect(result).toEqual('html')
  })

  it('returns "html_text" value for HTML formatted description, containing only a single pair of <p> tags', () => {
    const result = descriptionType('<p>Outcome Description</p>')
    expect(result).toEqual('html_text')
  })

  it('returns "html_text" value for HTML formatted description, containing only a single pair of <div> tags', () => {
    const result = descriptionType('<div>Outcome Description</div>')
    expect(result).toEqual('html_text')
  })

  it('returns "text" for text formatted description', () => {
    const result = descriptionType('Outcome Description')
    expect(result).toEqual('text')
  })
})

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

import LinkContentItem from '../LinkContentItem'

const thumbnail = 'https://www.test.com/thumbnail'
const json = {
  type: 'link',
  url: 'https://www.test.com',
  title: 'Title',
  text: 'some text',
  icon: 'https://www.test.com/icon',
  thumbnail,
  invalidProp: 'banana'
}

const linkContentItem = (overrides, selection) => {
  const mergedJson = {...json, ...overrides}
  return new LinkContentItem(mergedJson, '', selection)
}

describe('constructor', () => {
  it('sets the url when present', () => {
    expect(linkContentItem().url).toEqual(json.url)
  })

  it('sets the title when present', () => {
    expect(linkContentItem().title).toEqual(json.title)
  })

  it('sets the text when present', () => {
    expect(linkContentItem().text).toEqual(json.text)
  })

  it('sets the icon when present', () => {
    expect(linkContentItem().icon).toEqual(json.icon)
  })

  it('sets the thumbnail when present', () => {
    expect(linkContentItem().thumbnail).toEqual(json.thumbnail)
  })

  it('does not set invalid props', () => {
    expect(linkContentItem().invalidProp).toBeUndefined()
  })

  describe('when there is a user selection', () => {
    it('replaces "text" with the selection', () => {
      expect(linkContentItem({}, 'selection').text).toEqual('selection')
    })
  })
})

describe('toHtmlString', () => {
  it('correctly creates a link with the thumbnail', () => {
    expect(linkContentItem().toHtmlString()).toEqual(
      '<a href="https://www.test.com" title="Title"><img src="https://www.test.com/thumbnail" alt="some text"></a>'
    )
  })

  describe('when a thumbnail is not present', () => {
    const overrides = {thumbnail: undefined}
    it('creates an anchor tag with the correct values', () => {
      expect(linkContentItem(overrides).toHtmlString()).toEqual(
        '<a href="https://www.test.com" title="Title">some text</a>'
      )
    })
  })

  describe('when the link needs to be sanitized', () => {
    const overrides = {url: 'javascript:alert("hello world!");'}
    it('sanitizes the url', () => {
      expect(linkContentItem(overrides).toHtmlString()).toEqual(
        '<a href="#javascript:alert(&quot;hello world!&quot;);" title="Title"><img src="https://www.test.com/thumbnail" alt="some text"></a>'
      )
    })
  })
})

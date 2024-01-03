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

import {
  linkContentItem,
  linkContentItemToHtmlString,
  type LinkContentItem,
} from '../LinkContentItem'

const thumbnail = 'https://www.test.com/thumbnail'
const json = linkContentItem({
  url: 'https://www.test.com',
  title: 'Title',
  text: 'some text',
  icon: 'https://www.test.com/icon',
  thumbnail,
  lookup_uuid: '0b8fbc86-fdd7-4950-852d-ffa789b37ff2',
})

const overrideLinkContentItem = (overrides: Partial<LinkContentItem>) =>
  linkContentItem({...json, ...overrides})

describe('toHtmlString', () => {
  it('correctly creates a link with the thumbnail', () => {
    expect(linkContentItemToHtmlString(json)).toEqual(
      '<a href="https://www.test.com" title="Title" target="_blank"><img src="https://www.test.com/thumbnail" alt="some text"></a>'
    )
  })

  describe('when a thumbnail with width and height is present', () => {
    const overrides = {thumbnail: {width: 123, height: 456, url: 'https://www.test.com/thumb'}}
    it('creates a link with a thumbnail with width and height', () => {
      expect(linkContentItemToHtmlString(overrideLinkContentItem(overrides))).toEqual(
        '<a href="https://www.test.com" title="Title" target="_blank"><img src="https://www.test.com/thumb" alt="some text" width="123" height="456"></a>'
      )
    })
  })

  describe('when a thumbnail is not present', () => {
    const overrides = {thumbnail: undefined}
    it('creates an anchor tag with the correct values', () => {
      expect(linkContentItemToHtmlString(overrideLinkContentItem(overrides))).toEqual(
        '<a href="https://www.test.com" title="Title" target="_blank">some text</a>'
      )
    })
  })

  describe('when the link needs to be sanitized', () => {
    // eslint-disable-next-line no-script-url
    const overrides = {url: 'javascript:alert("hello world!");'}
    it('sanitizes the url', () => {
      expect(linkContentItemToHtmlString(overrideLinkContentItem(overrides))).toEqual(
        '<a href="#javascript:alert(&quot;hello world!&quot;);" title="Title" target="_blank"><img src="https://www.test.com/thumbnail" alt="some text"></a>'
      )
    })
  })

  describe('when the iframe property is specified', () => {
    const iframe = {
      src: 'http://www.instructure.com',
      width: 500,
      height: 200,
    }

    it('returns markup for an iframe', () => {
      expect(linkContentItemToHtmlString(overrideLinkContentItem({iframe}))).toEqual(
        '<iframe src="http://www.instructure.com" title="Title" allowfullscreen="true" allow="" style="width: 500px; height: 200px;"></iframe>'
      )
    })
  })
})

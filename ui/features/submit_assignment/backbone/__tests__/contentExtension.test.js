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
import {findContentExtension} from '../contentExtension'

describe('#findContentExtension', () => {
  describe('when the content has a media type', () => {
    it('returns the extension for the media type', () => {
      expect(findContentExtension({mediaType: 'application/json'})).toEqual('json')
    })
  })
  describe('when the content has an url', () => {
    it('returns the extension for the url', () => {
      expect(findContentExtension({url: 'http://foobar.com/q.json'})).toEqual('json')
    })
  })
  describe('when the content has a title', () => {
    it('returns the extension for the title', () => {
      expect(findContentExtension({title: 'x.json'})).toEqual('json')
    })
  })
  describe('when the content has text', () => {
    it('returns the extension for the text', () => {
      expect(findContentExtension({text: 'x.json'})).toEqual('json')
    })
  })
  describe('when the content has none of the above', () => {
    it('returns null', () => {
      expect(findContentExtension({})).toBeNull()
    })
  })
})

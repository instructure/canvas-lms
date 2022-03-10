/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import buildDownloadUrl from '../buildDownloadUrl'

describe('buildDownloadUrl()', () => {
  const subject = url => buildDownloadUrl(url)

  describe('when url is blank', () => {
    const url = undefined

    it('throws an error', () => {
      expect(() => subject(url)).toThrow('Error parsing')
    })
  })

  describe('when url is relative', () => {
    const url = '/files/1/download'

    it('throws an error', () => {
      expect(() => subject('/files/1/download')).toThrow('Error parsing')
    })
  })

  describe('when url is absolute', () => {
    let searchString

    const url = () => `http://canvas.instructure.com/files/1/download${searchString}`

    describe('when the url contains query params', () => {
      beforeEach(() => (searchString = '?foo=bar'))

      it('adds the new param and leaves the existing params', () => {
        expect(subject(url())).toMatchInlineSnapshot(
          `"http://canvas.instructure.com/files/1/download?foo=bar&icon_maker_icon=1"`
        )
      })
    })

    describe('when the url has no query params', () => {
      beforeEach(() => (searchString = ''))

      it('creates a new query string and adds the new param', () => {
        expect(subject(url())).toMatchInlineSnapshot(
          `"http://canvas.instructure.com/files/1/download?icon_maker_icon=1"`
        )
      })
    })
  })
})

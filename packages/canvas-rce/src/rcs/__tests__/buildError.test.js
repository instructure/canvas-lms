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

import buildError from '../buildError'

describe('buildError()', () => {
  let errorContext, error

  const subject = () => buildError(errorContext, error)

  const sharedExamplesForErrors = () => {
    it('yields an error variant', () => {
      expect(subject().variant).toEqual('error')
    })
  }

  describe('when the errorContext indicates a quota issue', () => {
    beforeEach(() => {
      errorContext = {message: 'file size exceeds quota'}
      error = undefined
    })

    it('yields the appropriate error message', () => {
      expect(subject().text).toEqual('File storage quota exceeded')
    })

    sharedExamplesForErrors()
  })

  describe('when the error indicates a caption size issue', () => {
    beforeEach(() => {
      error = {name: 'FileSizeError', maxBytes: 10000}
      errorContext = undefined
    })

    it('yields the appropriate error message', () => {
      expect(subject().text).toEqual('Closed caption file must be less than 10 kb')
    })

    sharedExamplesForErrors()
  })

  describe('when the errorContext indicates captions file failed to save', () => {
    beforeEach(() => {
      error = undefined
      errorContext = {message: 'failed to save captions'}
    })

    it('yields the appropriate error message', () => {
      expect(subject().text).toEqual('loading closed captions/subtitles failed.')
    })

    sharedExamplesForErrors()
  })

  describe("when the the errorContext and error don't match an error class", () => {
    beforeEach(() => {
      error = undefined
      errorContext = undefined
    })

    it('yields the default error message', () => {
      expect(subject().text).toEqual(
        'Something went wrong. Check your connection, reload the page, and try again.'
      )
    })

    sharedExamplesForErrors()
  })
})

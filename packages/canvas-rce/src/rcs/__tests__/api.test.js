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

import fetchMock from 'fetch-mock'
import RceApiSource from '../api'

let apiSource

beforeEach(() => {
  apiSource = new RceApiSource({
    jwt: 'theJWT',
    refreshToken: callback => {
      callback('freshJWT')
    },
    alertFunc: jest.fn()
  })
  fetchMock.mock('/api/session', '{}')
})

afterEach(() => fetchMock.restore())

describe('fetchImages()', () => {
  let props
  let standardProps = {
    contextType: 'course',
    images: {
      course: {}
    },
    sortBy: 'date'
  }

  const subject = () => apiSource.fetchImages(props)

  beforeEach(() => {
    apiSource.hasSession = true
    fetchMock.mock(/\/api\/documents*/, '[]')
  })

  describe('with "category" set', () => {
    props = {
      category: 'uncategorized',
      ...standardProps
    }
  })

  it('sends the category', async () => {
    subject()
    expect(
      fetchMock.called(
        '/api/documents?contextType=course&contextId=undefined&content_types=image&sort=undefined&order=undefined&category=uncategorized'
      )
    ).toEqual(true)
  })
})

describe('saveClosedCaptions()', () => {
  let apiProps, media_object_id, subtitles, maxBytes

  const subject = () =>
    apiSource.updateClosedCaptions(apiProps, {media_object_id, subtitles}, maxBytes)

  beforeEach(() => {
    apiProps = {host: 'test.com', jwt: 'asd.asdf.asdf'}
    media_object_id = 'm-id'
    subtitles = [
      {
        language: {selectedOptionId: 'en'},
        file: new Blob(['file contents'], {type: 'text/plain'}),
        isNew: true
      }
    ]
    maxBytes = undefined
  })

  describe('with a captions file that is too large', () => {
    beforeEach(() => {
      maxBytes = 5
    })

    it('Notifies the user of a file size issue', async () => {
      await subject()
      expect(apiSource.alertFunc).toHaveBeenCalledWith({
        text: 'Closed caption file must be less than 0.005 kb',
        variant: 'error'
      })
    })
  })
})

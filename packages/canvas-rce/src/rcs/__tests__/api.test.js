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
import {saveClosedCaptions, saveClosedCaptionsForAttachment} from '@instructure/canvas-media'
import RCEGlobals from '../../rce/RCEGlobals'

jest.mock('@instructure/canvas-media')

let apiSource

beforeEach(() => {
  apiSource = new RceApiSource({
    jwt: 'theJWT',
    refreshToken: callback => {
      callback('freshJWT')
    },
    alertFunc: jest.fn(),
  })

  apiSource.fetchPage = jest.fn()

  fetchMock.mock('/api/session', '{}')
})

afterEach(() => {
  fetchMock.restore()
})

describe('fetchImages()', () => {
  let props
  const standardProps = {
    contextType: 'course',
    images: {
      course: {},
    },
    sortBy: 'date',
  }

  const subject = () => apiSource.fetchImages(props)

  beforeEach(() => {
    apiSource.hasSession = true
    fetchMock.mock(/\/api\/documents*/, '{"files": []}')
  })

  describe('with "category" set', () => {
    props = {
      category: 'uncategorized',
      ...standardProps,
    }
  })

  it('sends the category', async () => {
    await subject()
    expect(
      fetchMock.called(
        '/api/documents?contextType=course&contextId=undefined&content_types=image&sort=undefined&order=undefined&category=uncategorized'
      )
    ).toEqual(true)
  })
})

describe('fetchFilesForFolder()', () => {
  let apiProps

  const subject = () => apiSource.fetchFilesForFolder(apiProps)

  beforeEach(() => {
    apiProps = {host: 'test.com', jwt: 'asd.asdf.asdf', filesUrl: '/api/files'}
    fetchMock.mock('/api/files', '{"files": []}')
  })

  it('fetches folder files without query params if none supplied in props', async () => {
    apiProps = {...apiProps}
    await subject()
    expect(apiSource.fetchPage).toHaveBeenCalledWith('/api/files', 'theJWT')
  })

  it('fetches folder files using the per_page query param', async () => {
    apiProps = {...apiProps, perPage: 5}
    await subject()
    expect(apiSource.fetchPage).toHaveBeenCalledWith('/api/files?per_page=5', 'theJWT')
  })

  it('fetches folder files using the encoded searchString query param', async () => {
    apiProps = {...apiProps, perPage: 5, searchString: 'an awesome file'}
    const encodedSearchString = encodeURIComponent(apiProps.searchString)
    await subject()
    expect(apiSource.fetchPage).toHaveBeenCalledWith(
      `/api/files?per_page=5&search_term=${encodedSearchString}`,
      'theJWT'
    )
  })
})

describe('fetchMedia', () => {
  let apiProps

  const subject = () => apiSource.fetchMedia(apiProps)

  beforeEach(() => {
    apiProps = {
      host: 'test.com',
      jwt: 'asd.asdf.asdf',
      contextType: 'course',
      media: {course: {}},
      sortBy: {
        sort: 'name',
        dir: 'asc',
      },
      contextId: 1,
    }

    apiSource.apiFetch = jest.fn()
    fetchMock.mock('/api/documents', '{"files": []}')
  })

  it('fetches media documents', async () => {
    await subject()
    expect(apiSource.apiFetch).toHaveBeenCalledWith(
      'http://test.com/api/documents?contextType=course&contextId=1&content_types=video,audio&sort=name&order=asc',
      {Authorization: 'Bearer theJWT'}
    )
  })
})

describe('saveClosedCaptions()', () => {
  let apiProps, media_object_id, attachment_id, subtitles, maxBytes

  const subject = params => apiSource.updateClosedCaptions(apiProps, params, maxBytes)

  beforeEach(() => {
    apiProps = {host: 'test.com', jwt: 'asd.asdf.asdf'}
    media_object_id = 'm-id'
    attachment_id = '123'
    subtitles = [
      {
        language: {selectedOptionId: 'en'},
        file: new Blob(['file contents'], {type: 'text/plain'}),
        isNew: true,
      },
    ]
    maxBytes = 10
  })

  afterEach(() => {
    jest.restoreAllMocks()
  })

  it('using media objects url', async () => {
    saveClosedCaptions.mockImplementation(() => Promise.resolve())
    await subject({media_object_id, subtitles})
    expect(saveClosedCaptions).toHaveBeenCalledWith(
      media_object_id,
      subtitles,
      {
        headers: {
          Authorization: 'Bearer asd.asdf.asdf',
        },
        origin: 'http://test.com',
      },
      maxBytes
    )
  })

  it('using media objects url due null attachment', async () => {
    attachment_id = null
    saveClosedCaptions.mockImplementation(() => Promise.resolve())
    await subject({media_object_id, attachment_id, subtitles})
    expect(saveClosedCaptions).toHaveBeenCalledWith(
      media_object_id,
      subtitles,
      {
        headers: {
          Authorization: 'Bearer asd.asdf.asdf',
        },
        origin: 'http://test.com',
      },
      maxBytes
    )
  })

  it('using media attachments url', async () => {
    saveClosedCaptionsForAttachment.mockImplementation(() => Promise.resolve())
    await subject({media_object_id, attachment_id, subtitles})
    expect(saveClosedCaptionsForAttachment).toHaveBeenCalledWith(
      attachment_id,
      subtitles,
      {
        headers: {
          Authorization: 'Bearer asd.asdf.asdf',
        },
        origin: 'http://test.com',
      },
      maxBytes
    )
  })

  describe('with a captions file that is too large', () => {
    beforeEach(() => {
      saveClosedCaptions.mockImplementation(
        jest.requireActual('@instructure/canvas-media').saveClosedCaptions
      )
      maxBytes = 5
    })

    it('Notifies the user of a file size issue', async () => {
      await subject({media_object_id, subtitles})
      expect(apiSource.alertFunc).toHaveBeenCalledWith({
        text: 'Closed caption file must be less than 0.005 kb',
        variant: 'error',
      })
    })
  })
})

describe('updateMediaData()', () => {
  const apiProps = {host: 'test.com', jwt: 'asd.asdf.asdf'}
  const media_object_id = 'm-id',
    attachment_id = '123'

  it('Uses the media object route with no attachment_id FF ON', async () => {
    apiSource.apiPost = jest.fn()
    await apiSource.updateMediaObject(apiProps, {media_object_id, title: '', attachment_id})
    expect(apiSource.apiPost).toHaveBeenCalledWith(
      'http://test.com/api/media_objects/m-id?user_entered_title=',
      expect.anything(),
      null,
      expect.anything()
    )
  })

  it('Uses the media attachment route with the attachment_id FF ON', async () => {
    apiSource.apiPost = jest.fn()
    RCEGlobals.getFeatures = jest.fn().mockReturnValue({media_links_use_attachment_id: true})
    await apiSource.updateMediaObject(apiProps, {media_object_id, title: '', attachment_id})
    expect(apiSource.apiPost).toHaveBeenCalledWith(
      'http://test.com/api/media_attachments/123?user_entered_title=',
      expect.anything(),
      null,
      expect.anything()
    )
  })
})

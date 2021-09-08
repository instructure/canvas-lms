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

import React from 'react'
import {render, waitFor} from '@testing-library/react'
import sinon from 'sinon'

import RceApiSource from '../../../../../sidebar/sources/api'

import SavedButtonList from '../SavedButtonList'
import {rceToFile} from '../SavedButtonList'

describe('RCE "Buttons and Icons" Plugin > SavedButtonList', () => {
  let defaultProps, fetchPageStub, globalFetchStub

  const apiSource = new RceApiSource({
    alertFunc: () => {},
    jwt: 'theJWT'
  })

  beforeEach(() => {
    globalFetchStub = sinon.stub(global, 'fetch')
    const context = {id: '101', type: 'course'}
    const buttonsAndIconsFolder = {filesUrl: 'http://rce.example.com/api/folders/52', id: '1'}
    const buttonAndIcon = {
      createdAt: '',
      id: 1,
      name: 'button.svg',
      thumbnailUrl: '',
      type: 'image/svg+xml',
      url: ''
    }
    const otherImage = {
      createdAt: '',
      id: 2,
      name: 'screenshot.jpg',
      thumbnailUrl: '',
      type: 'image/jpeg',
      url: ''
    }
    const folders = [buttonsAndIconsFolder]

    fetchPageStub = sinon.stub(apiSource, 'fetchPage')
    fetchPageStub
      .withArgs(`/api/folders/buttons_and_icons?contextType=course&contextId=${context.id}`)
      .returns(Promise.resolve({folders}))

    fetchPageStub
      .withArgs(
        'http://rce.example.com/api/folders/52?per_page=25&sort=created_at&order=desc',
        'theJWT'
      )
      .returns(Promise.resolve({bookmark: '', files: [buttonAndIcon, otherImage]}))

    defaultProps = {
      context,
      onImageEmbed: () => {},
      searchString: '',
      sortBy: {order: 'desc', sort: 'date_added'},
      source: apiSource
    }
  })

  afterEach(() => {
    fetchPageStub.restore()
    globalFetchStub.restore()
  })

  const renderComponent = componentProps => {
    return render(<SavedButtonList {...defaultProps} {...componentProps} />)
  }

  it('loads and displays svgs', async () => {
    const {getByAltText} = renderComponent()

    await waitFor(() => expect(getByAltText('button.svg')).toBeInTheDocument())
  })

  it('ignores non-svg files', async () => {
    const {queryByAltText} = renderComponent()

    await waitFor(() => queryByAltText('button.svg') != null)

    expect(queryByAltText('screenshot.jpg')).toBeNull()
  })
})

describe('rceToFile', () => {
  const rceFile = {
    createdAt: '2021-08-12T18:30:53Z',
    id: '101',
    name: 'kitten.gif',
    thumbnailUrl: 'http://example.com/kitten.png',
    type: 'image/gif',
    url: 'http://example.com/kitten.gif'
  }

  it('returns an object with type as content_type', () => {
    expect(rceToFile(rceFile).content_type).toStrictEqual('image/gif')
  })

  it('returns an object with createdAt as date', () => {
    expect(rceToFile(rceFile).date).toStrictEqual('2021-08-12T18:30:53Z')
  })

  it('returns an object with name as display_name', () => {
    expect(rceToFile(rceFile).display_name).toStrictEqual('kitten.gif')
  })

  it('returns an object with name as filename', () => {
    expect(rceToFile(rceFile).filename).toStrictEqual('kitten.gif')
  })

  it('returns an object with url as href', () => {
    expect(rceToFile(rceFile).href).toStrictEqual('http://example.com/kitten.gif')
  })

  it('returns an object with id as id', () => {
    expect(rceToFile(rceFile).id).toStrictEqual('101')
  })

  it('returns an object with thumbnailUrl as thumbnail_url', () => {
    expect(rceToFile(rceFile).thumbnail_url).toStrictEqual('http://example.com/kitten.png')
  })

  it('returns an object with the buttons/icons attr set to true', () => {
    expect(rceToFile(rceFile)['data-inst-buttons-and-icons']).toEqual(true)
  })
})

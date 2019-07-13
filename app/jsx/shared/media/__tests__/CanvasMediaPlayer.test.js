/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import CanvasMediaPlayer from '../CanvasMediaPlayer'
import moxios from 'moxios'
import React from 'react'
import {render} from 'react-testing-library'

const defaultMediaObject = () => ({
  bitrate: '12345',
  content_type: 'mp4',
  fileExt: 'mp4',
  height: '1234',
  isOriginal: 'false',
  size: '3123123123',
  src: 'anawesomeurl.test',
  label: 'an awesome label',
  width: '12345'
})


describe('CanvasMediaPlayer', () => {
  beforeEach(() => {
    moxios.install()
  })
  afterEach(() => {
    moxios.uninstall()
  })
  test('renders the component', () => {
    const {getByText} = render(
      <CanvasMediaPlayer mediaSources={[defaultMediaObject(), defaultMediaObject(), defaultMediaObject()]} />
    )
    expect(getByText('Play')).toBeInTheDocument()
  })

  test('renders loading if there are no media sources', () => {
    const {getByText} = render(
      <CanvasMediaPlayer mediaSources={[]} />
    )
    expect(getByText('Loading')).toBeInTheDocument()
  })

  test('make ajax call if no mediaSources are provided on load', (done) => {
    const {getByText} = render(
      <CanvasMediaPlayer mediaSources={[]} />
    )
    expect(getByText('Loading')).toBeInTheDocument()
    moxios.stubRequest('http://localhost/media_objects//info', {
      status: 200,
      response: {media_sources: [defaultMediaObject(), defaultMediaObject(), defaultMediaObject()]},
    })
    moxios.wait(() => {
      expect(getByText('Play')).toBeInTheDocument()
      done()
    })
  })

  test('renders loading if we receive no info from backend', (done) => {
    const {getByText} = render(
      <CanvasMediaPlayer mediaSources={[]} />
    )
    expect(getByText('Loading')).toBeInTheDocument()
    moxios.wait(() => {
        const request = moxios.requests.mostRecent()
        request.respondWith({
          status: 200,
          response: {media_sources: []}
        }).then(function () {
          expect(getByText('Loading')).toBeInTheDocument()
          done()
        })
    })
  })
})

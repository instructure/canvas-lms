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
import React from 'react'
import {render} from '@testing-library/react'
import waitForExpect from 'wait-for-expect'

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
    fetch.resetMocks()
  })

  it('renders the component', () => {
    const {getByText} = render(
      <CanvasMediaPlayer
        media_id="dummy_media_id"
        media_sources={[defaultMediaObject(), defaultMediaObject(), defaultMediaObject()]}
      />
    )
    expect(getByText('Play')).toBeInTheDocument()
  })

  it('renders loading if there are no media sources', () => {
    jest.spyOn(CanvasMediaPlayer.prototype, 'fetchSources').mockResolvedValue([])
    const {getByText} = render(<CanvasMediaPlayer media_id="dummy_media_id" mediaSources={[]} />)
    expect(getByText('Loading')).toBeInTheDocument()
    expect(fetch.mock.calls.length).toEqual(0)
    expect(CanvasMediaPlayer.prototype.fetchSources).toHaveBeenCalledTimes(1)
  })

  it('makes ajax call if no mediaSources are provided on load', async () => {
    jest.spyOn(CanvasMediaPlayer.prototype, 'fetchSources')

    fetch.mockResponseOnce(JSON.stringify({media_sources: [defaultMediaObject(), defaultMediaObject()]}))

    const {findByText} = render(<CanvasMediaPlayer media_id="dummy_media_id" />)
    expect(await findByText('Play')).toBeInTheDocument()
    expect(CanvasMediaPlayer.prototype.fetchSources).toHaveBeenCalledTimes(1)
    expect(fetch.mock.calls.length).toEqual(1)
    expect(fetch.mock.calls[0][0]).toEqual('/media_objects/dummy_media_id/info')
  })

  it('retries ajax call if no mediaSources on first call', async () => {
    fetch.mockResponses(
      [JSON.stringify({media_sources: []}), {status: 503}],
      [JSON.stringify({media_sources: [defaultMediaObject()]}), {status: 200}]
    )

    const {findByText} = render(<CanvasMediaPlayer media_id="dummy_media_id" />)

    expect(await findByText('Play')).toBeInTheDocument()
    expect(fetch.mock.calls.length).toEqual(2)
  })

  it('still says "Loading" if we receive no info from backend', async () => {
    fetch.mockResponse(JSON.stringify({media_sources: []}))

    const {getByText} = render(<CanvasMediaPlayer media_id="dummy_media_id" />)

    // wait for at least one request
    await waitForExpect(() => expect(fetch.mock.calls.length).toBeGreaterThan(0))

    // even after the server response came back, it should still say Loading
    expect(getByText('Loading')).toBeInTheDocument()
  })
})

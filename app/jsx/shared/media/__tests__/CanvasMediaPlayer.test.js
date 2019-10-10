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

import React from 'react'
import {render, waitForElement, act, cleanup} from '@testing-library/react'
import waitForExpect from 'wait-for-expect'
import CanvasMediaPlayer, {sizeMediaPlayer} from '../CanvasMediaPlayer'

afterEach(cleanup)

const defaultMediaObject = () => ({
  bitrate: '12345',
  content_type: 'video/mp4',
  fileExt: 'mp4',
  height: '1000',
  isOriginal: 'false',
  size: '3123123123',
  src: 'anawesomeurl.test',
  label: 'an awesome label',
  width: '500'
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
    let component
    act(() => {
      component = render(<CanvasMediaPlayer media_id="dummy_media_id" mediaSources={[]} />)
    })
    expect(component.getByText('Loading')).toBeInTheDocument()
    component.unmount()
  })

  it('makes ajax call if no mediaSources are provided on load', async () => {
    fetch.mockResponseOnce(
      JSON.stringify({media_sources: [defaultMediaObject(), defaultMediaObject()]})
    )

    let component
    act(() => {
      component = render(<CanvasMediaPlayer media_id="dummy_media_id" />)
    })
    expect(await component.findByText('Play')).toBeInTheDocument()
    expect(fetch.mock.calls.length).toEqual(1)
    expect(fetch.mock.calls[0][0]).toEqual('/media_objects/dummy_media_id/info')
    component.unmount()
  })

  it('retries ajax call if no mediaSources on first call', async () => {
    fetch.mockResponses(
      [JSON.stringify({media_sources: []}), {status: 503}],
      [JSON.stringify({media_sources: [defaultMediaObject()]}), {status: 200}]
    )

    let component
    act(() => {
      component = render(<CanvasMediaPlayer media_id="dummy_media_id" />)
    })

    const playButton = await waitForElement(() => component.getByText('Play'))

    expect(playButton).toBeInTheDocument()
    expect(fetch.mock.calls.length).toEqual(2)
    component.unmount()
  })

  it('still says "Loading" if we receive no info from backend', async () => {
    fetch.mockResponse(JSON.stringify({media_sources: []}))

    let component
    act(() => {
      component = render(<CanvasMediaPlayer media_id="dummy_media_id" />)
    })

    // wait for at least one request
    await waitForExpect(() => expect(fetch.mock.calls.length).toBeGreaterThan(0))

    // even after the server response came back, it should still say Loading
    expect(component.getByText('Loading')).toBeInTheDocument()
    component.unmount()
  })
  describe('sizeMediaPlayer', () => {
    it('sets an audio player size', () => {
      const {width, height} = sizeMediaPlayer({}, 'audio', {})
      expect(width).toBe('300px')
      expect(height).toBe('3rem')
    })

    it('scales a video player', () => {
      const player = {
        videoWidth: 1000,
        videoHeight: 600
      }
      const playerContainer = {
        clientWidth: 500
      }

      const {width, height} = sizeMediaPlayer(player, 'video', playerContainer)

      expect(width).toBe('500px')
      expect(height).toBe(`${Math.round(0.6 * 500)}px`)
    })
  })

  describe('renders correct set of video controls', () => {
    it('renders all the buttons', () => {
      document.fullscreenEnabled = true
      const {getByText, getByLabelText} = render(
        <CanvasMediaPlayer
          media_id="dummy_media_id"
          media_sources={[defaultMediaObject(), defaultMediaObject(), defaultMediaObject()]}
        />
      )
      expect(getByText('Play')).toBeInTheDocument()
      expect(getByLabelText('Timebar')).toBeInTheDocument()
      expect(getByText('Unmuted')).toBeInTheDocument()
      expect(getByText('Playback Speed')).toBeInTheDocument()
      expect(getByText('Source Chooser')).toBeInTheDocument()
      expect(getByText('Full Screen')).toBeInTheDocument()
    })

    it('skips fullscreen button when not enabled', () => {
      document.fullscreenEnabled = false
      const {queryByText, queryByLabelText} = render(
        <CanvasMediaPlayer
          media_id="dummy_media_id"
          media_sources={[defaultMediaObject(), defaultMediaObject(), defaultMediaObject()]}
        />
      )
      expect(queryByText('Play')).toBeInTheDocument()
      expect(queryByLabelText('Timebar')).toBeInTheDocument()
      expect(queryByText('Unmuted')).toBeInTheDocument()
      expect(queryByText('Playback Speed')).toBeInTheDocument()
      expect(queryByText('Source Chooser')).toBeInTheDocument()
      expect(queryByText('Full Screen')).not.toBeInTheDocument()
    })

    it('skips source chooser button when there is only 1 source', () => {
      document.fullscreenEnabled = true
      const {queryByText, queryByLabelText} = render(
        <CanvasMediaPlayer media_id="dummy_media_id" media_sources={[defaultMediaObject()]} />
      )
      expect(queryByText('Play')).toBeInTheDocument()
      expect(queryByLabelText('Timebar')).toBeInTheDocument()
      expect(queryByText('Unmuted')).toBeInTheDocument()
      expect(queryByText('Playback Speed')).toBeInTheDocument()
      expect(queryByText('Source Chooser')).not.toBeInTheDocument()
      expect(queryByText('Full Screen')).toBeInTheDocument()
    })
  })
})

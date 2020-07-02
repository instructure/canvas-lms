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
import {render, wait, waitForElement, fireEvent, act, cleanup} from '@testing-library/react'
import {queries as domQueries} from '@testing-library/dom'
import waitForExpect from 'wait-for-expect'
import CanvasMediaPlayer, {setPlayerSize} from '../CanvasMediaPlayer'
import {uniqueId} from 'lodash'

const defaultMediaObject = (overrides = {}) => ({
  bitrate: '12345',
  content_type: 'video/mp4',
  fileExt: 'mp4',
  height: '500',
  isOriginal: 'false',
  size: '3123123123',
  src: uniqueId('anawesomeurl-') + '.test',
  label: 'an awesome label',
  width: '1000',
  ...overrides
})
describe('CanvasMediaPlayer', () => {
  beforeEach(() => {
    fetch.resetMocks()
    jest.useFakeTimers()
  })
  afterEach(async () => {
    jest.resetAllMocks()
  })
  it('renders the component', () => {
    const {container, getAllByText} = render(
      <CanvasMediaPlayer
        media_id="dummy_media_id"
        media_sources={[defaultMediaObject(), defaultMediaObject(), defaultMediaObject()]}
      />
    )
    // need queryAll because some of the buttons have tooltip and text
    expect(getAllByText('Play')[0]).toBeInTheDocument()
    expect(container.querySelector('video')).toBeInTheDocument()
  })
  // While this test passes, including it causes jest.runAllTimers() to emit a message
  // "Ran 100000 timers, and there are still more! Assuming we've hit an infinite recursion and bailing out..."
  // and fail subsequent tests. I cannot figure out why.
  it.skip('sorts sources by bitrate, ascending', () => {
    const {container, getAllByText} = render(
      <CanvasMediaPlayer
        media_id="dummy_media_id"
        media_sources={[
          defaultMediaObject({bitrate: '3000', label: '3000'}),
          defaultMediaObject({bitrate: '2000', label: '2000'}),
          defaultMediaObject({bitrate: '1000', label: '1000'})
        ]}
      />
    )
    const sourceChooser = getAllByText('Source Chooser')[0].closest('button')
    fireEvent.click(sourceChooser)
    const sourceList = container.querySelectorAll(
      'ul[aria-label="Source Chooser"] ul[role="menu"] li'
    )
    expect(domQueries.getByText(sourceList[0], '1000')).toBeInTheDocument()
    expect(domQueries.getByText(sourceList[1], '2000')).toBeInTheDocument()
    expect(domQueries.getByText(sourceList[2], '3000')).toBeInTheDocument()
  })
  it('handles string-type media_sources', () => {
    // seen for audio files
    const {getAllByText} = render(
      <CanvasMediaPlayer
        media_id="dummy_media_id"
        media_sources="http://localhost:3000/files/797/download?download_frd=1"
        type="audio"
      />
    )
    // just make sure it doesn't blow up and renders the player
    expect(getAllByText('Play')[0]).toBeInTheDocument()
  })
  it('renders loading if there are no media sources', async () => {
    let component
    await act(async () => {
      component = render(<CanvasMediaPlayer media_id="dummy_media_id" mediaSources={[]} />)
      expect(component.getByText('Loading')).toBeInTheDocument()
    })
    await act(async () => {
      jest.runOnlyPendingTimers()
      await wait()
      cleanup()
    })
  })
  it('makes ajax call if no mediaSources are provided on load', async () => {
    fetch.mockResponseOnce(
      JSON.stringify({media_sources: [defaultMediaObject(), defaultMediaObject()]})
    )
    await act(async () => {
      render(<CanvasMediaPlayer media_id="dummy_media_id" />)
      jest.runAllTimers()
      await wait()
    })
    expect(fetch.mock.calls.length).toEqual(1)
    expect(fetch.mock.calls[0][0]).toEqual('/media_objects/dummy_media_id/info')
    await act(async () => {
      jest.runOnlyPendingTimers()
      await wait()
      cleanup()
    })
  })
  it('retries ajax call if no media_sources on first call', async () => {
    fetch.mockResponses(
      [JSON.stringify({error: 'whoops'}), {status: 503}],
      [JSON.stringify({media_sources: [defaultMediaObject()]}), {status: 200}]
    )
    await act(async () => {
      render(<CanvasMediaPlayer media_id="dummy_media_id" />)
      jest.runAllTimers()
      await wait()
      jest.runAllTimers()
      await wait()
    })
    expect(fetch.mock.calls.length).toEqual(2)
  })
  it('tries ajax call up to 5 times if no media_sources', async () => {
    fetch.mockResponses(
      [JSON.stringify({media_sources: []}), {status: 200}],
      [JSON.stringify({media_sources: []}), {status: 200}],
      [JSON.stringify({media_sources: []}), {status: 200}],
      [JSON.stringify({media_sources: []}), {status: 200}],
      [JSON.stringify({media_sources: []}), {status: 200}],
      [JSON.stringify({media_sources: []}), {status: 200}]
    )
    let component
    await act(async () => {
      component = render(<CanvasMediaPlayer media_id="dummy_media_id" />)
      expect(component.getByText('Loading')).toBeInTheDocument()
      jest.runAllTimers() // triggers useEffect
      await wait() // render
      jest.runAllTimers()
      await wait()
      jest.runAllTimers()
      await wait()
      jest.runAllTimers()
      await wait()
      jest.runAllTimers()
      await wait()
    })
    expect(fetch.mock.calls.length).toEqual(5)
    const erralert = await waitForElement(() =>
      component.getByText('Failed retrieving media source')
    )
    expect(erralert).toBeInTheDocument()
    await act(async () => {
      jest.runOnlyPendingTimers()
      await wait()
      cleanup()
    })
  })
  it('still says "Loading" if we receive no info from backend', async () => {
    fetch.mockResponse(JSON.stringify({media_sources: []}))
    let component
    await act(async () => {
      component = render(<CanvasMediaPlayer media_id="dummy_media_id" />)
    })
    // wait for at least one request
    await waitForExpect(() => expect(fetch.mock.calls.length).toBeGreaterThan(0))
    // even after the server response came back, it should still say Loading
    expect(component.getAllByText('Loading')[0]).toBeInTheDocument()
    await act(async () => {
      jest.runOnlyPendingTimers()
      await wait()
      cleanup()
    })
  })
  describe('renders correct set of video controls', () => {
    it('renders all the buttons', () => {
      document.fullscreenEnabled = true
      const {getAllByText, getByLabelText, queryAllByText, queryByLabelText} = render(
        <CanvasMediaPlayer
          media_id="dummy_media_id"
          media_sources={[defaultMediaObject(), defaultMediaObject(), defaultMediaObject()]}
        />
      )
      // need queryAll because some of the buttons have tooltip and text
      // (in v7 of the player, so let's just do it now)
      expect(getAllByText('Play')[0]).toBeInTheDocument()
      expect(getByLabelText('Timebar')).toBeInTheDocument()
      expect(getAllByText('Unmuted')[0]).toBeInTheDocument()
      expect(getAllByText('Playback Speed')[0]).toBeInTheDocument()
      expect(queryByLabelText('Source Chooser')).not.toBeInTheDocument()
      expect(getAllByText('Full Screen')[0]).toBeInTheDocument()
      expect(queryAllByText('Video Track').length).toBe(0) // AKA CC
    })
    it('skips fullscreen button when not enabled', () => {
      document.fullscreenEnabled = false
      const {getAllByText, getByLabelText, queryAllByText, queryByLabelText} = render(
        <CanvasMediaPlayer
          media_id="dummy_media_id"
          media_sources={[defaultMediaObject(), defaultMediaObject(), defaultMediaObject()]}
        />
      )
      expect(getAllByText('Play')[0]).toBeInTheDocument()
      expect(getByLabelText('Timebar')).toBeInTheDocument()
      expect(getAllByText('Unmuted')[0]).toBeInTheDocument()
      expect(getAllByText('Playback Speed')[0]).toBeInTheDocument()
      expect(queryByLabelText('Source Chooser')).not.toBeInTheDocument()
      expect(queryAllByText('Full Screen').length).toBe(0)
      expect(queryAllByText('Video Track').length).toBe(0) // AKA CC
    })
    it('skips source chooser button when there is only 1 source', () => {
      document.fullscreenEnabled = true
      const {getAllByText, getByLabelText, queryAllByText, queryByLabelText} = render(
        <CanvasMediaPlayer media_id="dummy_media_id" media_sources={[defaultMediaObject()]} />
      )
      expect(getAllByText('Play')[0]).toBeInTheDocument()
      expect(getByLabelText('Timebar')).toBeInTheDocument()
      expect(getAllByText('Unmuted')[0]).toBeInTheDocument()
      expect(getAllByText('Playback Speed')[0]).toBeInTheDocument()
      expect(queryByLabelText('Source Chooser')).not.toBeInTheDocument()
      expect(getAllByText('Full Screen')[0]).toBeInTheDocument()
      expect(queryAllByText('Video Track').length).toBe(0) // AKA CC
    })
    it('includes the CC button when there are subtitle track(s)', () => {
      const {getAllByText, getByLabelText, queryByLabelText} = render(
        <CanvasMediaPlayer
          media_id="dummy_media_id"
          media_sources={[defaultMediaObject()]}
          media_tracks={[
            {label: 'English', language: 'en', src: '/media_objects/more/stuff', type: 'subtitles'}
          ]}
        />
      )
      expect(getAllByText('Play')[0]).toBeInTheDocument()
      expect(getByLabelText('Timebar')).toBeInTheDocument()
      expect(getAllByText('Unmuted')[0]).toBeInTheDocument()
      expect(getAllByText('Playback Speed')[0]).toBeInTheDocument()
      expect(queryByLabelText('Source Chooser')).not.toBeInTheDocument()
      expect(getAllByText('Video Track')[0]).toBeInTheDocument() // AKA CC
    })
  })

  describe('renders the right size', () => {
    const makePlayer = (w, h) => {
      return {
        videoWidth: w,
        videoHeight: h,
        style: {},
        classList: {
          add: jest.fn()
        }
      }
    }

    it('when the media is audio', () => {
      const container = document.createElement('div')
      const player = makePlayer(1000, 500)
      setPlayerSize(player, 'audio/*', {width: 400, height: 200}, container)
      expect(player.classList.add).toHaveBeenCalledWith('audio-player')
      expect(player.style.width).toBe('320px')
      expect(player.style.height).toBe('14.25rem')
      expect(container.style.width).toBe('320px')
      expect(container.style.height).toBe('14.25rem')
    })

    it('when the video is landscape', () => {
      const container = document.createElement('div')
      const player = makePlayer(1000, 500)
      setPlayerSize(player, 'video/*', {width: 400, height: 200}, container)
      expect(player.classList.add).toHaveBeenCalledWith('video-player')
      expect(player.style.width).toBe('400px')
      expect(player.style.height).toBe('200px')
      expect(container.style.width).toBe('400px')
      expect(container.style.height).toBe('200px')
    })

    it('when the video is portrait', () => {
      const container = document.createElement('div')
      const player = makePlayer(500, 1000)
      setPlayerSize(player, 'video/*', {width: 400, height: 200}, container)
      expect(player.classList.add).toHaveBeenCalledWith('video-player')
      expect(player.style.width).toBe('100px')
      expect(player.style.height).toBe('200px')
      expect(container.style.width).toBe('')
      expect(container.style.height).toBe('')
    })

    it('shrinks the height for short and squat videos', () => {
      const container = document.createElement('div')
      const player = makePlayer(1000, 100)
      setPlayerSize(player, 'video/*', {width: 400, height: 200}, container)
      expect(player.classList.add).toHaveBeenCalledWith('video-player')
      expect(player.style.width).toBe('400px')
      expect(player.style.height).toBe('40px')
      expect(container.style.width).toBe('400px')
      expect(container.style.height).toBe('40px')
    })
  })
})

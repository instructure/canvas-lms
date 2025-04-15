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

// These tests got a bit hairy because CanvasStudioPlayer keeps attempting to
// fetch media_sources on a timer until it gets them. Unless we satisfy its
// needs, it will fetch even after the component is unmounted.

// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-nocheck
import React from 'react'
import {render, waitFor, fireEvent, act} from '@testing-library/react'
import {queries as domQueries, screen} from '@testing-library/dom'
import CanvasStudioPlayer, {formatTracksForMediaPlayer} from '../CanvasStudioPlayer'
import {uniqueId} from 'lodash'
import fetchMock from 'fetch-mock'

const defaultMediaObject = (overrides = {}) => ({
  bitrate: '12345',
  content_type: 'video/mp4',
  fileExt: 'mp4',
  height: '500',
  isOriginal: 'false',
  size: '3123123123',
  src: 'http://' + uniqueId('anawesomeurl-') + '.test',
  label: 'an awesome label',
  width: '1000',
  ...overrides,
})

function setPlayerSize(player, type, dimensions, container, resizeContainer = true) {}

// TODO: The studio-player does not work with jest
// revisit unit tests if they upgrade it to play nicer
describe.skip('CanvasStudioPlayer', () => {
  describe('rendering', () => {
    beforeAll(() => {
      // put the flash_screenreader_holder into the dom
      let d = document.createElement('div')
      d.id = 'flash_screenreader_holder'
      d.setAttribute('role', 'alert')
      document.body.appendChild(d)
      // the specs looking for Alert text found
      // 2 copies, one in the screenreader message
      // and 1 in the component. let's give the
      // component a place to render so the getByText
      // queries don't look in the flash_screenreader_holder
      d = document.createElement('div')
      d.id = 'here'
      d.innerHTML = '<div></div>'
      document.body.appendChild(d)
    })

    beforeEach(() => {
      // @ts-expect-error
      jest.useFakeTimers()
      fetchMock.get(/\/media_objects\/\d+\/info/, {
        media_sources: [defaultMediaObject()],
      })
    })
    afterEach(() => {
      act(() => {
        jest.runOnlyPendingTimers()
      })
      jest.resetAllMocks()
      jest.useRealTimers()
    })

    it('renders the component', () => {
      const {container, getAllByText} = render(
        <CanvasStudioPlayer
          media_id="dummy_media_id"
          media_sources={[defaultMediaObject(), defaultMediaObject(), defaultMediaObject()]}
        />,
      )
      screen.logTestingPlaygroundURL()
      fireEvent.canPlay(container.querySelector('video')!)
      // need queryAll because some of the buttons have tooltip and text
      expect(getAllByText('Play')[0]).toBeInTheDocument()
      expect(container.querySelector('video')).toBeInTheDocument()
    })
    it.skip('sorts sources by bitrate, ascending', () => {
      // ARC-9206
      const {container, getAllByText, getByRole} = render(
        <CanvasStudioPlayer
          media_id="dummy_media_id"
          media_sources={[
            defaultMediaObject({bitrate: '3000', label: '3000'}),
            defaultMediaObject({bitrate: '2000', label: '2000'}),
            defaultMediaObject({bitrate: '1000', label: '1000'}),
          ]}
        />,
      )
      fireEvent.canPlay(container.querySelector('video'))
      const settings = getByRole('button', {
        name: /settings/i,
      })
      fireEvent.click(settings)
      const sourceChooser = getAllByText('Quality')[0].closest('button')
      fireEvent.click(sourceChooser)
      const sourceList = container.querySelectorAll('[role="menuitemradio"]')
      expect(domQueries.getByText(sourceList[0], '1000')).toBeInTheDocument()
      expect(domQueries.getByText(sourceList[1], '2000')).toBeInTheDocument()
      expect(domQueries.getByText(sourceList[2], '3000')).toBeInTheDocument()
    })

    it('adds aria-label for screenreaders when provided in props', () => {
      const label = 'Video file 1.mp4'
      const {container} = render(
        <CanvasStudioPlayer
          media_id="dummy_media_id"
          media_sources={[defaultMediaObject(), defaultMediaObject(), defaultMediaObject()]}
          aria_label={label}
        />,
      )
      expect(
        container.querySelector(`div[aria-label="Video player for ${label}"]`),
      ).toBeInTheDocument()
    })

    it('omits aria-label for screenreaders when not provided in props', () => {
      const {container} = render(
        <CanvasStudioPlayer
          media_id="dummy_media_id"
          media_sources={[defaultMediaObject(), defaultMediaObject(), defaultMediaObject()]}
        />,
      )
      const divWithAria = container.querySelectorAll('[aria-label^="Video player for"]')
      expect(divWithAria).toHaveLength(0)
    })

    it('renders and overlay to prevent media right clicks', () => {
      const {container} = render(
        <CanvasStudioPlayer
          media_id="dummy_media_id"
          media_sources={[defaultMediaObject(), defaultMediaObject(), defaultMediaObject()]}
        />,
      )
      const video = container.querySelector('video')
      const overlay = video.parentElement.parentElement.parentElement.children[1].children[0]
      expect(overlay.children).toHaveLength(0)
    })

    describe('dealing with media_sources', () => {
      it.skip('renders loading if there are no media sources', async () => {
        // MAT-885
        const {getAllByText} = render(
          <CanvasStudioPlayer media_id="dummy_media_id" mediaSources={[]} />,
        )
        expect(getAllByText('Loading')[0]).toBeInTheDocument()
        jest.runOnlyPendingTimers()
        expect(fetchMock.calls()).toHaveLength(1)
      })
      it('makes ajax call if no mediaSources are provided on load', async () => {
        fetchMock.getOnce(
          /\/media_objects\/\d+\/info/,
          {
            media_sources: [defaultMediaObject(), defaultMediaObject()],
          },
          {
            overwriteRoutes: true,
          },
        )
        render(<CanvasStudioPlayer media_id="dummy_media_id" />)
        jest.runOnlyPendingTimers()
        expect(fetchMock.calls()).toHaveLength(1)
        expect(fetchMock.calls()[0][0]).toEqual('/media_objects/dummy_media_id/info')
      })
      it('makes ajax call to media_attachments if no mediaSources are provided on load', async () => {
        fetchMock.getOnce(
          /\/media_attachments\/.*\/info/,
          {
            media_sources: [defaultMediaObject(), defaultMediaObject()],
          },
          {
            overwriteRoutes: true,
          },
        )
        render(<CanvasStudioPlayer media_id="dummy_media_id" attachment_id="1" />)
        jest.runOnlyPendingTimers()
        expect(fetchMock.calls()).toHaveLength(1)
        expect(fetchMock.calls()[0][0]).toEqual('/media_attachments/1/info')
      })
      it.skip('shows error message if fetch for media_sources fails', async () => {
        // MAT-885
        fetchMock.getOnce(/\/media_objects\/\d+\/info/, 500, {overwriteRoutes: true})
        const component = render(<CanvasStudioPlayer media_id="dummy_media_id" />, {
          container: document.getElementById('here').firstElementChild,
        })
        act(() => {
          jest.runOnlyPendingTimers()
        })

        expect(fetchMock.calls()).toHaveLength(1)
        expect(component.getByText('Failed retrieving media sources.')).toBeInTheDocument()
      })
      it.skip('tries ajax call up to MAX times if no media_sources', async () => {
        // Note that the comment below was written while we were still using jest-fetch-mock,
        // which used cross-fetch and jest.mock/jest.spyOn. It's possible that fetchMock
        // avoids these issues somehow. Good luck traveler.
        // MAT-885
        // this spec passes if run alone, but fails as part of the larger suite
        // what I see happening is fetch.mock.calls is getting reset to 0 because the mock
        // can't find the instance. see canvas-lms/node_modules/jest-mock/build/index.js
        // at line 345 where
        // let state = this._mockState.get(f);
        // returns undefined
        // It might be because CanvasStudioPlayer is a function component so each invocation
        // creates a new fetch mock? (though that doesn't explain why it works when it's the only test run)
        // it also doesn't explain why this passed before using ui-media-player 7
        fetchMock
          .getOnce(
            '/media_objects/dummy_media_id/info',
            new Response({media_sources: []}, {status: 200}),
          )
          .get(
            '/media_objects/dummy_media_id/info',
            new Response({media_sources: []}, {status: 304}),
          )

        let component
        await act(async () => {
          component = render(
            <CanvasStudioPlayer
              media_id="dummy_media_id"
              MAX_RETRY_ATTEMPTS={5}
              SHOW_BE_PATIENT_MSG_AFTER_ATTEMPTS={2}
            />,
            {
              container: document.getElementById('here').firstElementChild,
            },
          )

          expect(component.getByText('Loading')).toBeInTheDocument()
          await act(async () => {
            await waitFor(() => {
              jest.runOnlyPendingTimers()
              expect(fetchMock.calls()).toHaveLength(1)
            })
          })
          expect(component.getByText('Loading')).toBeInTheDocument()
          expect(document.getElementById('flash_screenreader_holder').textContent).toMatch(
            /Loading/,
          )
          await act(async () => {
            await waitFor(() => {
              jest.runOnlyPendingTimers()
              expect(fetchMock.calls()).toHaveLength(2)
            })
          })
          await act(async () => {
            await waitFor(() => {
              jest.runOnlyPendingTimers()
              expect(fetchMock.calls()).toHaveLength(3)
            })
          })
          expect(
            component.getByText(
              'Your media has been uploaded and will appear here after processing.',
              {
                exact: false,
              },
            ),
          ).toBeInTheDocument()
          expect(document.getElementById('flash_screenreader_holder').textContent).toMatch(
            /Your media has been uploaded and will appear here after processing./,
          )
          await act(async () => {
            await waitFor(() => {
              jest.runOnlyPendingTimers()
              expect(fetchMock.calls()).toHaveLength(4)
            })
          })
          await act(async () => {
            await waitFor(() => {
              jest.runOnlyPendingTimers()
              expect(fetchMock.calls()).toHaveLength(5)
            })
          })
          await act(async () => {
            await waitFor(() => {
              jest.runOnlyPendingTimers()
              expect(fetchMock.calls()).toHaveLength(6)
            })
          })
          // add a 7th iteration just to prove the queries stopped at MAX_RETRY_ATTEMPTS
          await act(async () => {
            jest.runOnlyPendingTimers()
            await waitFor(() => {})
          })

          expect(fetchMock.calls()).toHaveLength(6) // initial attempt + 5 MAX_RETRY_ATTEMPTS
          expect(
            component.getByText(
              'Giving up on retrieving media sources. This issue will probably resolve itself eventually.',
              {exact: false},
            ),
          ).toBeInTheDocument()
          expect(document.getElementById('flash_screenreader_holder').textContent).toMatch(
            /Giving up on retrieving media sources. This issue will probably resolve itself eventually./,
          )

          jest.runOnlyPendingTimers()
          await waitFor(() => {})
        })
      })
      it.skip('still says "Loading" if we receive no info from backend', async () => {
        // MAT-885
        fetchMock.getOnce(/\/media_objects\/\d+\/info/, {media_sources: []})

        let component
        await act(async () => {
          component = render(<CanvasStudioPlayer media_id="dummy_media_id" />, {
            container: document.getElementById('here').firstElementChild,
          })
          expect(component.getByText('Loading')).toBeInTheDocument()

          await act(async () => {
            await waitFor(() => {
              jest.runOnlyPendingTimers()
              expect(fetchMock.calls()).toHaveLength(1)
            })
          })
        })
        expect(component.getByText('Loading')).toBeInTheDocument()
      })
    })
    describe('renders correct set of video controls', () => {
      it('renders all the buttons', () => {
        document.fullscreenEnabled = true
        const {
          getAllByText,
          getByLabelText,
          queryAllByText,
          queryByLabelText,
          container,
          getByRole,
        } = render(
          <CanvasStudioPlayer media_id="dummy_media_id" media_sources={[defaultMediaObject()]} />,
        )
        fireEvent.canPlay(container.querySelector('video'))
        const settings = getByRole('button', {
          name: /settings/i,
        })
        fireEvent.click(settings)
        // need queryAll because some of the buttons have tooltip and text
        // (in v7 of the player, so let's just do it now)
        expect(getAllByText('Play')[0]).toBeInTheDocument()
        expect(getByLabelText('Timebar')).toBeInTheDocument()
        expect(getAllByText('Volume')[0]).toBeInTheDocument()
        expect(getAllByText('Speed')[0]).toBeInTheDocument()
        expect(queryByLabelText('Quality')).not.toBeInTheDocument()
        expect(getAllByText('Full Screen')[0]).toBeInTheDocument()
        expect(queryAllByText('Captions')).toHaveLength(0) // AKA CC
      })
      it('skips fullscreen button when not enabled', () => {
        document.fullscreenEnabled = false
        const {
          getAllByText,
          getByLabelText,
          queryAllByText,
          queryByLabelText,
          container,
          getByRole,
        } = render(
          <CanvasStudioPlayer media_id="dummy_media_id" media_sources={[defaultMediaObject()]} />,
        )
        fireEvent.canPlay(container.querySelector('video'))
        const settings = getByRole('button', {
          name: /settings/i,
        })
        fireEvent.click(settings)
        expect(getAllByText('Play')[0]).toBeInTheDocument()
        expect(getByLabelText('Timebar')).toBeInTheDocument()
        expect(getAllByText('Volume')[0]).toBeInTheDocument()
        expect(getAllByText('Speed')[0]).toBeInTheDocument()
        expect(queryByLabelText('Quality')).not.toBeInTheDocument()
        expect(queryAllByText('Full Screen')).toHaveLength(0)
        expect(queryAllByText('Captions')).toHaveLength(0) // AKA CC
      })
      it('skips source chooser button when there is only 1 source', () => {
        document.fullscreenEnabled = true
        const {
          getAllByText,
          getByLabelText,
          queryAllByText,
          queryByLabelText,
          container,
          getByRole,
        } = render(
          <CanvasStudioPlayer media_id="dummy_media_id" media_sources={[defaultMediaObject()]} />,
        )
        fireEvent.canPlay(container.querySelector('video'))
        const settings = getByRole('button', {
          name: /settings/i,
        })
        fireEvent.click(settings)
        expect(getAllByText('Play')[0]).toBeInTheDocument()
        expect(getByLabelText('Timebar')).toBeInTheDocument()
        expect(getAllByText('Volume')[0]).toBeInTheDocument()
        expect(getAllByText('Speed')[0]).toBeInTheDocument()
        expect(queryByLabelText('Quality')).not.toBeInTheDocument()
        expect(getAllByText('Full Screen')[0]).toBeInTheDocument()
        expect(queryAllByText('Captions')).toHaveLength(0) // AKA CC
      })
      describe("for safari's fullscreen api", () => {
        beforeAll(() => {
          document.fullscreenEnabled = undefined
        })
        it('renders all the buttons', () => {
          document.webkitFullscreenEnabled = true
          const {getAllByText, container} = render(
            <CanvasStudioPlayer
              media_id="dummy_media_id"
              media_sources={[defaultMediaObject(), defaultMediaObject(), defaultMediaObject()]}
            />,
          )
          fireEvent.canPlay(container.querySelector('video'))
          expect(getAllByText('Full Screen')[0]).toBeInTheDocument()
        })
        it('skips fullscreen button when not enabled', () => {
          document.webkitFullscreenEnabled = false
          const {queryAllByText, container} = render(
            <CanvasStudioPlayer
              media_id="dummy_media_id"
              media_sources={[defaultMediaObject(), defaultMediaObject(), defaultMediaObject()]}
            />,
          )
          fireEvent.canPlay(container.querySelector('video'))
          expect(queryAllByText('Full Screen')).toHaveLength(0)
        })
        it('skips source chooser button when there is only 1 source', () => {
          document.webkitFullscreenEnabled = true
          const {getAllByText, container, queryByLabelText} = render(
            <CanvasStudioPlayer media_id="dummy_media_id" media_sources={[defaultMediaObject()]} />,
          )
          fireEvent.canPlay(container.querySelector('video'))
          expect(getAllByText('Full Screen')[0]).toBeInTheDocument()
          expect(queryByLabelText('Quality')).not.toBeInTheDocument()
        })
      })
      it('includes the CC button when there are subtitle track(s)', () => {
        const {getAllByText, getByLabelText, queryByLabelText, container, getByRole} = render(
          <CanvasStudioPlayer
            media_id="dummy_media_id"
            media_sources={[defaultMediaObject()]}
            media_tracks={[
              {
                id: '1',
                src: '/media_objects/more/stuff',
                label: 'English',
                language: 'en',
                type: 'subtitles',
                inherited: false,
              },
            ]}
          />,
        )
        fireEvent.canPlay(container.querySelector('video'))
        const settings = getByRole('button', {
          name: /settings/i,
        })
        fireEvent.click(settings)
        expect(getAllByText('Play')[0]).toBeInTheDocument()
        expect(getByLabelText('Timebar')).toBeInTheDocument()
        expect(getAllByText('Volume')[0]).toBeInTheDocument()
        expect(getAllByText('Speed')[0]).toBeInTheDocument()
        expect(queryByLabelText('Quality')).not.toBeInTheDocument()
        expect(getAllByText('Captions')[0]).toBeInTheDocument() // AKA CC
      })
    })
  })

  describe('renders the video element right size', () => {
    const makePlayer = (w, h) => {
      return {
        videoWidth: w,
        videoHeight: h,
        offsetWidth: w,
        offsetHeight: h,
        style: {},
        classList: {
          add: jest.fn(),
        },
      }
    }

    it('does not resize the container when passed resizeContainer = false', () => {
      const container = document.createElement('div')
      container.style.height = '300px'
      container.style.width = '500px'
      const player = makePlayer(1000, 500)
      setPlayerSize(player, 'audio/*', {width: 400, height: 200}, container, false)
      expect(player.classList.add).toHaveBeenCalledWith('audio-player')
      expect(player.style.width).toBe('320px')
      expect(player.style.height).toBe('14.25rem')
      expect(container.style.width).toBe('500px')
      expect(container.style.height).toBe('300px')
    })

    it('does not resize the container when the player is not visible', () => {
      const container = document.createElement('div')
      container.style.width = '500px'
      container.style.height = '300px'
      const player = makePlayer(1000, 500)
      player.offsetHeight = 0
      setPlayerSize(player, 'video/*', {width: 400, height: 200}, container)
      expect(container.style.width).toBe('500px')
      expect(container.style.height).toBe('300px')
    })

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

    it('when the video is fullscreen landscape', async () => {
      const container = document.createElement('div')
      const player = makePlayer(500, 250)
      document.fullscreenElement = container
      setPlayerSize(player, 'video/*', {width: 1000, height: 800}, null)
      expect(player.classList.add).toHaveBeenCalledWith('video-player')
      expect(player.style.width).toBe('1000px')
      expect(player.style.height).toBe('500px')
    })

    it('when the video is fullscreen portrait', () => {
      const container = document.createElement('div')
      const player = makePlayer(250, 500)
      document.fullscreenElement = container
      setPlayerSize(player, 'video/*', {width: 1000, height: 800}, null)
      expect(player.classList.add).toHaveBeenCalledWith('video-player')
      expect(player.style.width).toBe('400px')
      expect(player.style.height).toBe('800px')
    })
    describe("for safari's fullscreen api", () => {
      it('when the video is fullscreen landscape', async () => {
        const container = document.createElement('div')
        const player = makePlayer(500, 250)
        document.webkitFullscreenElement = container
        setPlayerSize(player, 'video/*', {width: 1000, height: 800}, null)
        expect(player.classList.add).toHaveBeenCalledWith('video-player')
        expect(player.style.width).toBe('1000px')
        expect(player.style.height).toBe('500px')
      })

      it('when the video is fullscreen portrait', () => {
        const container = document.createElement('div')
        const player = makePlayer(250, 500)
        document.webkitFullscreenElement = container
        setPlayerSize(player, 'video/*', {width: 1000, height: 800}, null)
        expect(player.classList.add).toHaveBeenCalledWith('video-player')
        expect(player.style.width).toBe('400px')
        expect(player.style.height).toBe('800px')
      })
    })
  })
})

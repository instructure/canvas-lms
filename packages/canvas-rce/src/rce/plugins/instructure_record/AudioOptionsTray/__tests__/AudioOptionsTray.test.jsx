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
import {fireEvent, render, screen, waitFor} from '@testing-library/react'
import {HttpResponse, http} from 'msw'
import {setupServer} from 'msw/node'

import AudioOptionsTray from '..'
import AudioOptionsTrayDriver from './AudioOptionsTrayDriver'
import {createLiveRegion, removeLiveRegion} from '../../../../__tests__/liveRegionHelper'
import RCEGlobals from '../../../../../rce/RCEGlobals'

const server = setupServer()

describe('RCE "Audios" Plugin > AudioOptionsTray', () => {
  let props
  let tray

  beforeAll(() => server.listen({onUnhandledRequest: 'error'}))

  afterAll(() => server.close())

  beforeEach(() => {
    createLiveRegion()

    props = {
      onRequestClose: jest.fn(),
      onSave: jest.fn(),
      open: true,
      requestSubtitlesFromIframe: jest.fn(),
      audioOptions: {
        id: 'm-audio-id',
        titleText: 'Audio player',
        tracks: [{locale: 'en', inherited: false}],
      },
      trayProps: {
        host: 'localhost:3001',
        jwt: 'someuglyvalue',
      },
    }
  })

  afterEach(() => {
    removeLiveRegion()
  })

  function renderComponent() {
    render(<AudioOptionsTray {...props} />)
    tray = AudioOptionsTrayDriver.find()
  }

  it('is optionally rendered open', () => {
    props.open = true
    renderComponent()
    expect(tray).not.toBeNull()
  })

  it('is optionally rendered closed', () => {
    props.open = false
    renderComponent()
    expect(tray).toBeNull()
  })

  it('is labeled with "Audio Options Tray"', () => {
    renderComponent()
    expect(tray.label).toEqual('Audio Options Tray')
  })

  it('when clicked calls the .onSave prop', () => {
    renderComponent()
    tray.$doneButton.click()
    expect(props.onSave).toHaveBeenCalledTimes(1)
  })

  describe('requestSubtitlesFromIframe', () => {
    it('is not called when subtitles are present', () => {
      renderComponent()
      expect(props.requestSubtitlesFromIframe).not.toHaveBeenCalled()
    })

    it('is called when no subtitles present', () => {
      props.audioOptions.tracks = null
      renderComponent()
      expect(props.requestSubtitlesFromIframe).toHaveBeenCalledTimes(1)
    })
  })

  describe('"Done" button', () => {
    const expectNoTooltip = () => {
      fireEvent.mouseEnter(tray.$doneButton)
      expect(screen.queryByText('Unsaved changes will be lost.')).not.toBeInTheDocument()
    }

    const renderLoadedComponent = async () => {
      props.open = true
      renderComponent()
      await waitFor(() => {
        expect(tray.$manualCaptionsAddNewButton).toBeInTheDocument()
      })
    }

    beforeEach(() => {
      jest.spyOn(RCEGlobals, 'getFeatures').mockReturnValue({rce_asr_captioning_improvements: true})
    })

    describe("doesn't show tooltip", () => {
      it('by default', async () => {
        await renderLoadedComponent()
        expectNoTooltip()
      })

      describe('with manual captions', () => {
        it('if there are no changes applied', async () => {
          await renderLoadedComponent()
          fireEvent.click(tray.$manualCaptionsAddNewButton)
          expectNoTooltip()
        })

        it('if changes are cancelled', async () => {
          await renderLoadedComponent()
          fireEvent.click(tray.$manualCaptionsAddNewButton)
          fireEvent.click(tray.$manualCaptionsLanguageSelect)
          fireEvent.click(screen.getByText('Catalan'))
          fireEvent.click(tray.$manualCaptionsCancelButton)
          expectNoTooltip()
        })

        it.skip('if changes are applied', async () => {
          server.use(
            http.put('**/api/media_objects/*/media_tracks', () =>
              HttpResponse.json({data: 'success'}),
            ),
          )

          await renderLoadedComponent()

          fireEvent.click(tray.$manualCaptionsAddNewButton)
          fireEvent.click(tray.$manualCaptionsLanguageSelect)
          fireEvent.click(screen.getByText('Catalan'))
          fireEvent.change(tray.$manualCaptionsFileInput, {
            target: {files: [{name: 'auto-generated-en.vtt'}]},
          })
          fireEvent.click(tray.$manualCaptionsUploadButton)
          expectNoTooltip()
        })
      })

      describe('with automatic captions', () => {
        it('if there are no changes applied', async () => {
          await renderLoadedComponent()
          fireEvent.click(tray.$automaticCaptionsAddNewButton)
          expectNoTooltip()
        })

        it('if changes are cancelled', async () => {
          await renderLoadedComponent()
          fireEvent.click(tray.$automaticCaptionsAddNewButton)
          fireEvent.click(tray.$automaticCaptionsLanguageSelect)
          fireEvent.click(screen.getByText('German'))
          fireEvent.click(tray.$automaticCaptionsCancelButton)
          expectNoTooltip()
        })

        it('if changes are applied', async () => {
          await renderLoadedComponent()
          fireEvent.click(tray.$automaticCaptionsAddNewButton)
          fireEvent.click(tray.$automaticCaptionsLanguageSelect)
          fireEvent.click(screen.getByText('German'))
          fireEvent.click(tray.$automaticCaptionsRequestButton)
          expectNoTooltip()
        })
      })
    })

    describe('shows tooltip', () => {
      const expectTooltip = () => {
        fireEvent.mouseEnter(tray.$doneButton)
        expect(screen.getByText('Unsaved changes will be lost.')).toBeInTheDocument()
      }

      describe('with manual captions', () => {
        it('if there are changes applied', async () => {
          await renderLoadedComponent()
          fireEvent.click(tray.$manualCaptionsAddNewButton)
          fireEvent.click(tray.$manualCaptionsLanguageSelect)
          fireEvent.click(screen.getByText('Catalan'))
          expectTooltip()
        })
      })

      describe('with automatic captions', () => {
        it('if there are changes applied', async () => {
          await renderLoadedComponent()
          fireEvent.click(tray.$automaticCaptionsAddNewButton)
          fireEvent.click(tray.$automaticCaptionsLanguageSelect)
          fireEvent.click(screen.getByText('German'))
          expectTooltip()
        })
      })
    })
  })
})

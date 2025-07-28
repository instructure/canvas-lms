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
import {render, screen, waitFor} from '@testing-library/react'

import VideoOptionsTray from '..'
import VideoOptionsTrayDriver from './VideoOptionsTrayDriver'
import {createLiveRegion, removeLiveRegion} from '../../../../__tests__/liveRegionHelper'
import RCEGlobals from '../../../../../rce/RCEGlobals'
jest.useFakeTimers()

describe('RCE "Videos" Plugin > VideoOptionsTray', () => {
  let props
  let tray

  beforeEach(() => {
    createLiveRegion()

    props = {
      onRequestClose: jest.fn(),
      onSave: jest.fn(),
      open: true,
      requestSubtitlesFromIframe: jest.fn(),
      videoOptions: {
        $element: null,
        appliedHeight: 180,
        appliedWidth: 320,
        id: 'm-video-id',
        naturalHeight: 730,
        naturalWidth: 1280,
        source: {},
        titleText: '',
        tracks: [{locale: 'en', inherited: false}],
        type: 'video-embed',
        videoSize: 'medium',
        usePercentageUnits: false,
      },
      trayProps: {
        host: 'localhost:3001',
        jwt: 'someuglyvalue',
      },
    }
  })

  afterEach(() => {
    removeLiveRegion()
    jest.resetAllMocks()
  })

  function renderComponent() {
    render(<VideoOptionsTray {...props} />)
    tray = VideoOptionsTrayDriver.find()
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

  it('is labeled with "Video Options Tray"', () => {
    renderComponent()
    expect(tray.label).toEqual('Video Options Tray')
  })

  describe('Title field', () => {
    it('uses the value of titleText in the given video options', () => {
      props.videoOptions.titleText = 'A turtle in a party suit.'
      renderComponent()
      expect(tray.titleText).toEqual('A turtle in a party suit.')
    })

    it('is blank when the given video options titleText is blank', () => {
      props.videoOptions.titleText = ''
      renderComponent()
      expect(tray.titleText).toEqual('')
    })
  })

  describe('"Display Options" field', () => {
    it('is set to "embed" by default', () => {
      renderComponent()
      expect(tray.displayAs).toEqual('embed')
    })

    it('can be set to "Display Text Link"', () => {
      renderComponent()
      tray.setDisplayAs('link')
      expect(tray.displayAs).toEqual('link')
    })

    it('can be reset to "Embed Image"', () => {
      renderComponent()
      tray.setDisplayAs('link')
      tray.setDisplayAs('embed')
      expect(tray.displayAs).toEqual('embed')
    })
  })

  describe('"Size" field', () => {
    it('is set using the given image options', () => {
      renderComponent()
      expect(tray.size).toEqual('Medium')
    })

    it('can be re-set to "Medium"', async () => {
      renderComponent()
      await tray.setSize('Large')
      await tray.setSize('Medium')
      expect(tray.size).toEqual('Medium')
    })

    it('can be set to "Large"', async () => {
      renderComponent()
      await tray.setSize('Large')
      expect(tray.size).toEqual('Large')
    })

    it('can be set to "Custom"', async () => {
      renderComponent()
      await tray.setSize('Custom')
      expect(tray.size).toEqual('Custom')
    })

    it('requires 320px custom width', () => {
      props.videoOptions.videoSize = 'custom'
      props.videoOptions.appliedWidth = 310
      renderComponent()
      // I don't know why, but getByText does not find the string,
      // though I can prove it's there
      expect(/Pixels must be at least 320 x 186px/.test(tray.messageText())).toBeTruthy()
    })

    describe('when consolidated_media_player feature flag is enabled', () => {
      beforeEach(() => {
        jest.spyOn(RCEGlobals, 'getFeatures').mockReturnValue({consolidated_media_player: true})
      })
      it('can be set to "Small"', async () => {
        renderComponent()
        await tray.setSize('Small')
        expect(tray.size).toEqual('Small')
        expect(screen.getByText(/320 x 254px/i)).toBeInTheDocument()
      })

      it('can be set to "Medium"', async () => {
        renderComponent()
        await tray.setSize('Medium')
        expect(tray.size).toEqual('Medium')
        expect(screen.getByText(/480 x 300px/i)).toBeInTheDocument()
      })

      it('can be set to "Large"', async () => {
        renderComponent()
        await tray.setSize('Large')
        expect(tray.size).toEqual('Large')
        expect(screen.getByText(/700 x 441px/i)).toBeInTheDocument()
      })

      it('can be set to "Custom"', async () => {
        renderComponent()
        await tray.setSize('Custom')
        expect(tray.size).toEqual('Custom')
      })

      it('properly sets default size option', async () => {
        props.videoOptions.videoSize = 'large'
        renderComponent()
        await waitFor(() => {
          expect(tray.size).toEqual('Large')
        })
      })

      it('requires 320px custom width', () => {
        props.videoOptions.videoSize = 'custom'
        props.videoOptions.appliedWidth = 319
        props.videoOptions.appliedHeight = 254
        renderComponent()
        expect(/Pixels must be at least 320 x 254px/.test(tray.messageText())).toBeTruthy()
      })

      it('requires 254px custom height', () => {
        props.videoOptions.videoSize = 'custom'
        props.videoOptions.appliedWidth = 320
        props.videoOptions.appliedHeight = 253
        renderComponent()
        expect(/Pixels must be at least 320 x 254px/.test(tray.messageText())).toBeTruthy()
      })
    })
  })

  describe('"Closed Captions Panel"', () => {
    it('is displayed when feature flag is true', async () => {
      renderComponent()
      await waitFor(() => {
        expect(tray.$closedCaptionPanel).toBeInTheDocument()
      })
    })

    it('does not steal focus when changing other parts of the tray', async () => {
      renderComponent()
      await waitFor(() => {
        expect(tray.$closedCaptionPanel).toBeInTheDocument()
      })
      tray.$titleTextField.focus()
      tray.setTitleText('hello')
      expect(tray.$titleTextField).toBe(document.activeElement)
    })
  })

  describe('"Done" button', () => {
    describe('when Title Text is present', () => {
      beforeEach(() => {
        renderComponent()
        tray.setTitleText('A turtle in a party suit.')
      })

      it('is enabled', () => {
        expect(tray.doneButtonDisabled).toEqual(false)
      })
    })

    describe('when Title Text is not present', () => {
      beforeEach(() => {
        renderComponent()
        tray.setTitleText('')
      })

      it('is disabled ', () => {
        expect(tray.doneButtonDisabled).toEqual(true)
      })

      it('is enabled when "Display Text Link" is selected', () => {
        tray.setDisplayAs('link')
        expect(tray.doneButtonDisabled).toEqual(false)
      })
    })
  })
})

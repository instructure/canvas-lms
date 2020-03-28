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
import {render} from '@testing-library/react'

import VideoOptionsTray from '..'
import VideoOptionsTrayDriver from './VideoOptionsTrayDriver'

describe('RCE "Videos" Plugin > VideoOptionsTray', () => {
  let props
  let tray

  beforeEach(() => {
    window.ENV = {
      FEATURES: {
        cc_in_rce_video_tray: true
      }
    }

    props = {
      onRequestClose: jest.fn(),
      onSave: jest.fn(),
      open: true,
      videoOptions: {
        $element: null,
        appliedHeight: 180,
        appliedWidth: 320,
        id: 'm-video-id',
        naturalHeight: 730,
        naturalWidth: 1280,
        source: {},
        titleText: '',
        type: 'video-embed',
        videoSize: 'medium'
      },
      trayOptions: {
        host: 'localhost:3001',
        jwt: 'someuglyvalue'
      }
    }
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
  })

  describe('"Closed Captions Panel"', () => {
    it('is displayed when feature flag is true', () => {
      renderComponent()
      expect(tray.$closedCaptionPanel).toBeInTheDocument()
    })

    it('is not displayed when feature flag is false', () => {
      window.ENV.FEATURES.cc_in_rce_video_tray = false
      renderComponent()
      expect(tray.$closedCaptionPanel).toBeNull()
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

  describe('when clicked', () => {
    beforeEach(() => {
      renderComponent()
      tray.setTitleText('A turtle in a party suit.')
    })

    it('prevents the default click handler', () => {
      const preventDefault = jest.fn()
      // Override preventDefault before event reaches image
      tray.$doneButton.addEventListener(
        'click',
        event => {
          Object.assign(event, {preventDefault})
        },
        true
      )
      tray.$doneButton.click()
      expect(preventDefault).toHaveBeenCalledTimes(1)
    })

    it('calls the .onSave prop', () => {
      tray.$doneButton.click()
      expect(props.onSave).toHaveBeenCalledTimes(1)
    })

    describe('when calling the .onSave prop', () => {
      it('includes the Title Text', () => {
        tray.setTitleText('A turtle in a party suit.')
        tray.$doneButton.click()
        const [{titleText}] = props.onSave.mock.calls[0]
        expect(titleText).toEqual('A turtle in a party suit.')
      })

      it('includes the "Display As" setting', () => {
        tray.setDisplayAs('link')
        tray.$doneButton.click()
        const [{displayAs}] = props.onSave.mock.calls[0]
        expect(displayAs).toEqual('link')
      })

      it('includes the size to be applied', async () => {
        await tray.setSize('Large')
        tray.$doneButton.click()
        const [{appliedHeight, appliedWidth}] = props.onSave.mock.calls[0]
        expect(appliedWidth).toEqual(400)
        const expectedHt = Math.round(
          (props.videoOptions.naturalHeight / props.videoOptions.naturalWidth) * 400
        )
        expect(appliedHeight).toEqual(expectedHt)
      })
    })
  })
})

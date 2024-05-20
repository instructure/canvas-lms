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
import {render} from '@testing-library/react'

import AudioOptionsTray from '..'
import AudioOptionsTrayDriver from './AudioOptionsTrayDriver'
import {createLiveRegion, removeLiveRegion} from '../../../../__tests__/liveRegionHelper'

describe('RCE "Audios" Plugin > AudioOptionsTray', () => {
  let props
  let tray

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
})

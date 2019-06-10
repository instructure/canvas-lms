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
import {render} from 'react-testing-library'

import VideoOptionsTray from '..'
import VideoOptionsTrayDriver from './VideoOptionsTrayDriver'

describe('RCE "Videos" Plugin > VideoOptionsTray', () => {
  let props
  let tray

  beforeEach(() => {
    props = {
      videoOptions: {
        size: 'medium'
      },
      onRequestClose: jest.fn(),
      onSave: jest.fn(),
      open: true
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

  describe('"Size" field', () => {
    it('is set to "Medium" by default', () => {
      renderComponent()
      expect(tray.size).toEqual('Medium')
    })

    it('can be set to "Small"', async () => {
      renderComponent()
      await tray.setSize('Small')
      expect(tray.size).toEqual('Small')
    })

    it('can be re-set to "Medium"', async () => {
      renderComponent()
      await tray.setSize('Small')
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

  describe('"Done" button', () => {
    describe('when clicked', () => {
      beforeEach(async () => {
        renderComponent()
        await tray.setSize("Large")
      })

      it('prevents the default click handler', () => {
        const preventDefault = jest.fn()
        // Override preventDefault before event reaches video
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
        it('includes the Size', async () => {
          await tray.setSize('Large')
          tray.$doneButton.click()
          const [{videoSize}] = props.onSave.mock.calls[0]
          expect(videoSize).toEqual('large')
        })
      })
    })
  })
})

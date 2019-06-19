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
})

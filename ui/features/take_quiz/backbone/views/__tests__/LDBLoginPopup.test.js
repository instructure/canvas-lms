/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import $ from 'jquery'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import LDBLoginPopup from '../LDBLoginPopup'

const server = setupServer()

describe('LDBLoginPopup', () => {
  let popup
  let mockWindow

  beforeAll(() => {
    server.listen()
  })

  afterAll(() => {
    server.close()
  })

  beforeEach(() => {
    popup = new LDBLoginPopup({sticky: false})
    mockWindow = {
      document: {
        write: jest.fn(),
        close: jest.fn(),
        find: jest.fn(() => ({
          length: $('link').length,
          trigger: jest.fn(),
        })),
      },
      close: jest.fn(),
      onbeforeunload: null,
      onload: null,
    }
    global.window.open = jest.fn().mockReturnValue(mockWindow)
  })

  afterEach(() => {
    jest.clearAllMocks()
    server.resetHandlers()
  })

  it('creates a popup window when executed', () => {
    const whnd = popup.exec()
    expect(window.open).toHaveBeenCalled()
    expect(whnd).toBe(mockWindow)
  })

  it('injects stylesheets into the popup window', () => {
    const whnd = popup.exec()
    const mainLinks = $('link')
    expect(whnd.document.find('link[href]')).toHaveLength(mainLinks.length)
  })

  it('closes after a successful login', () => {
    jest.useFakeTimers()
    const onClose = jest.fn()

    server.use(
      http.get('*', () => {
        return HttpResponse.text('OK', {status: 200})
      }),
    )

    popup.on('close', onClose)
    popup.on('open', (e, document) => {
      document.find('.btn-primary').trigger('click')
      jest.advanceTimersByTime(1)
      expect(onClose).toHaveBeenCalled()
    })

    popup.exec()
    jest.useRealTimers()
  })

  it('triggers login_success event after successful login', () => {
    jest.useFakeTimers()
    const onSuccess = jest.fn()

    server.use(
      http.get('*', () => {
        return HttpResponse.text('OK', {status: 200})
      }),
    )

    popup.on('login_success', onSuccess)
    popup.on('open', (e, document) => {
      document.find('.btn-primary').trigger('click')
      jest.advanceTimersByTime(1)
      expect(onSuccess).toHaveBeenCalled()
    })

    popup.exec()
    jest.useRealTimers()
  })
})

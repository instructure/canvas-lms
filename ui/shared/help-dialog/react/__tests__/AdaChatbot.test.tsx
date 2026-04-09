/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import fakeENV from '@canvas/test-utils/fakeENV'
import {render, cleanup} from '@testing-library/react'
import AdaChatbot, {
  getAdaMetaFields,
  launchAdaPopup,
  ADA_MSG_POPUP_READY,
  ADA_MSG_META_FIELDS,
} from '../AdaChatbot'
import {openWindow} from '@canvas/util/globalUtils'

vi.mock('@canvas/util/globalUtils', () => ({
  openWindow: vi.fn(() => null),
}))

const mockOpenWindow = openWindow as unknown as ReturnType<typeof vi.fn>

function simulatePopupReady(popupWindow: object) {
  window.dispatchEvent(
    new MessageEvent('message', {
      data: {type: ADA_MSG_POPUP_READY},
      origin: window.location.origin,
      source: popupWindow as unknown as MessageEventSource,
    }),
  )
}

describe('AdaChatbot', () => {
  const mockOnDialogClose = vi.fn()

  beforeEach(() => {
    fakeENV.setup({
      ADA_CHATBOT_ENABLED: true,
      current_user: {
        email: 'test@example.com',
        display_name: 'Test User',
      },
      current_user_roles: ['teacher', 'admin'],
      DOMAIN_ROOT_ACCOUNT_UUID: 'test-uuid',
    })
    vi.clearAllMocks()
  })

  afterEach(() => {
    cleanup()
    fakeENV.teardown()
  })

  it('renders nothing', () => {
    const {container} = render(<AdaChatbot onDialogClose={mockOnDialogClose} />)
    expect(container.firstChild).toBeNull()
  })

  it('opens popup window and calls onDialogClose', () => {
    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)
    expect(mockOpenWindow).toHaveBeenCalledTimes(1)
    expect(mockOnDialogClose).toHaveBeenCalledTimes(1)
  })

  it('opens popup to the Canvas-hosted popup path', () => {
    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)
    const [url, target, features] = mockOpenWindow.mock.calls[0]
    expect(url).toBe('/ada_chat_popup')
    expect(target).toBe('AdaChatPopup')
    expect(features).toBe('width=500,height=700,resizable=yes,scrollbars=yes')
  })

  it('does not open popup when Ada is disabled', () => {
    fakeENV.setup({ADA_CHATBOT_ENABLED: false})
    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)
    expect(mockOpenWindow).not.toHaveBeenCalled()
    expect(mockOnDialogClose).toHaveBeenCalledTimes(1)
  })

  it('still calls onDialogClose when popup is blocked', () => {
    mockOpenWindow.mockReturnValue(null)
    render(<AdaChatbot onDialogClose={mockOnDialogClose} />)
    expect(mockOpenWindow).toHaveBeenCalledTimes(1)
    expect(mockOnDialogClose).toHaveBeenCalledTimes(1)
  })

  describe('postMessage handshake', () => {
    let mockPopup: {postMessage: ReturnType<typeof vi.fn>}

    beforeEach(() => {
      mockPopup = {postMessage: vi.fn()}
      mockOpenWindow.mockReturnValue(mockPopup)
    })

    it('sends metadata to popup when it signals ready', () => {
      render(<AdaChatbot onDialogClose={mockOnDialogClose} />)
      simulatePopupReady(mockPopup)

      expect(mockPopup.postMessage).toHaveBeenCalledWith(
        {
          type: ADA_MSG_META_FIELDS,
          metaFields: expect.objectContaining({
            launchedUrl: expect.any(String),
            institutionUrl: expect.any(String),
            canvasRoles: 'teacher,admin',
            canvasUUID: 'test-uuid',
            isAdmin: 'true',
            isTeacher: 'true',
            isStudent: 'false',
            isRootAdmin: 'false',
            isObserver: 'false',
          }),
          sensitiveMetaFields: {
            email: 'test@example.com',
            name: 'Test User',
          },
        },
        window.location.origin,
      )
    })

    it('puts email and name in sensitiveMetaFields, not metaFields', () => {
      render(<AdaChatbot onDialogClose={mockOnDialogClose} />)
      simulatePopupReady(mockPopup)

      const payload = mockPopup.postMessage.mock.calls[0][0]
      expect(payload.sensitiveMetaFields).toEqual({
        email: 'test@example.com',
        name: 'Test User',
      })
      expect(payload.metaFields).not.toHaveProperty('email')
      expect(payload.metaFields).not.toHaveProperty('name')
    })

    it('ignores ready signals from other origins', () => {
      render(<AdaChatbot onDialogClose={mockOnDialogClose} />)

      window.dispatchEvent(
        new MessageEvent('message', {
          data: {type: ADA_MSG_POPUP_READY},
          origin: 'https://evil.com',
          source: mockPopup as unknown as MessageEventSource,
        }),
      )

      expect(mockPopup.postMessage).not.toHaveBeenCalled()
    })

    it('ignores messages with an unrecognised type', () => {
      render(<AdaChatbot onDialogClose={mockOnDialogClose} />)

      window.dispatchEvent(
        new MessageEvent('message', {
          data: {type: 'SOMETHING_ELSE'},
          origin: window.location.origin,
          source: mockPopup as unknown as MessageEventSource,
        }),
      )

      expect(mockPopup.postMessage).not.toHaveBeenCalled()
    })
  })

  describe('getAdaMetaFields', () => {
    it('returns email and name in sensitiveMetaFields', () => {
      const {sensitiveMetaFields} = getAdaMetaFields()
      expect(sensitiveMetaFields.email).toBe('test@example.com')
      expect(sensitiveMetaFields.name).toBe('Test User')
    })

    it('returns role flags in metaFields', () => {
      const {metaFields} = getAdaMetaFields()
      expect(metaFields.isAdmin).toBe('true')
      expect(metaFields.isTeacher).toBe('true')
      expect(metaFields.isStudent).toBe('false')
      expect(metaFields.isRootAdmin).toBe('false')
      expect(metaFields.isObserver).toBe('false')
    })

    it('includes launchedUrl in metaFields', () => {
      const {metaFields} = getAdaMetaFields()
      expect(metaFields.launchedUrl).toBe(window.location.href)
    })

    it('defaults to empty strings when user data is missing', () => {
      fakeENV.setup({
        current_user: {},
        current_user_roles: [],
        DOMAIN_ROOT_ACCOUNT_UUID: '',
      })
      const {sensitiveMetaFields, metaFields} = getAdaMetaFields()
      expect(sensitiveMetaFields).toEqual({email: '', name: ''})
      expect(metaFields.canvasRoles).toBe('')
      expect(metaFields.canvasUUID).toBe('')
    })

    it('sets isRootAdmin to true when user has root_admin role', () => {
      fakeENV.setup({
        current_user: {email: 'admin@example.com', display_name: 'Admin'},
        current_user_roles: ['root_admin', 'admin'],
        DOMAIN_ROOT_ACCOUNT_UUID: 'test-uuid',
      })
      const {metaFields} = getAdaMetaFields()
      expect(metaFields.isRootAdmin).toBe('true')
      expect(metaFields.isAdmin).toBe('true')
    })
  })

  describe('launchAdaPopup', () => {
    it('opens a popup to the Canvas-hosted popup path', () => {
      launchAdaPopup()
      expect(mockOpenWindow).toHaveBeenCalledTimes(1)
      expect(mockOpenWindow.mock.calls[0][0]).toBe('/ada_chat_popup')
    })

    it('replaces pending listener when popup is already open', () => {
      const firstPopup = {postMessage: vi.fn()}
      const secondPopup = {postMessage: vi.fn()}

      mockOpenWindow.mockReturnValue(firstPopup)
      launchAdaPopup()

      mockOpenWindow.mockReturnValue(secondPopup)
      launchAdaPopup()

      simulatePopupReady(secondPopup)

      expect(secondPopup.postMessage).toHaveBeenCalledTimes(1)
      expect(firstPopup.postMessage).not.toHaveBeenCalled()
    })
  })
})

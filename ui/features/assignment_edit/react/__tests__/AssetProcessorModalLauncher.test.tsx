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
import { render, screen, waitFor, fireEvent } from '@testing-library/react'
import '@testing-library/jest-dom/extend-expect'
import $ from 'jquery'
import { AssetProcessorModalLauncher } from '../AssetProcessorModalLauncher';

jest.mock('jquery', () => ({
  get: jest.fn(),
}))

describe('AssetProcessorModalLauncher', () => {
  const origEnv = {...window.ENV}
  const origin = 'http://example.com'
  beforeEach(() => {
    document.body.innerHTML = '<div id="root"></div>'
    window.ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN = origin
  })

  afterEach(() => {
    document.body.innerHTML = ''
    jest.clearAllMocks()
    window.ENV = origEnv
  })

  it('fetches tools on mount', async () => {
    const tools = [{ name: 'Tool 1', definition_id: 1 }]
    jest.spyOn($, 'get').mockImplementation((...args) => {
      const callback = (args as any)[2];
      return callback(tools)
    })
    render(<AssetProcessorModalLauncher />)
    await waitFor(() => expect($.get).toHaveBeenCalled())
    expect(screen.getByText('Attach AP - Tool 1')).toBeInTheDocument()
  })

  it('opens modal on button click', async () => {
    const tools = [{ name: 'Tool 1', definition_id: 1 }]
    jest.spyOn($, 'get').mockImplementation((...args) => {
      const callback = (args as any)[2];
      return callback(tools)
    })
    render(<AssetProcessorModalLauncher />)
    fireEvent.click(screen.getByText('Attach AP - Tool 1'))
    expect(screen.getByText('Deep Link AP - Tool 1')).toBeInTheDocument()
  })

  it('fills in hidden input fields on modal close', async () => {
    const sendPostMessage = (data: any) =>
      fireEvent(window, new MessageEvent('message', {data, origin}))
    const mockData = [
      {
        type: 'ltiAssetProcessor',
        url: 'https://example.com/tool1',
        title: 'Tool 1',
        text: 'Description for Tool 1',
        custom: JSON.stringify({ key: 'value1' }),
        icon: JSON.stringify({ url: 'https://example.com/icon1.png' }),
        window: JSON.stringify({ target: '_blank' }),
        iframe: JSON.stringify({ width: 800, height: 600 }),
        report: JSON.stringify({ enabled: true }),
      }
    ]

    const tools = [{ name: 'Tool 1', definition_id: 1 }]
    jest.spyOn($, 'get').mockImplementation((...args) => {
      const callback = (args as any)[2];
      return callback(tools)
    })
    render(<AssetProcessorModalLauncher />)
    await waitFor(() => expect($.get).toHaveBeenCalled())
    fireEvent.click(screen.getByText('Attach AP - Tool 1'))
    sendPostMessage({
      subject: 'LtiDeepLinkingResponse',
      tool_id: '1',
      content_items: mockData,
    })

    await waitFor(() => { expect(screen.getByTestId('asset_processors[0][0][url]')).toBeInTheDocument() })
    expect((screen.getByTestId('asset_processors[0][0][url]') as HTMLInputElement).value).toBe(mockData[0].url)
  })
})

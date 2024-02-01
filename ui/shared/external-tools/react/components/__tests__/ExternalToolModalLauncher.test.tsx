/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {render, waitFor, fireEvent} from '@testing-library/react'
import ExternalToolModalLauncher from '../ExternalToolModalLauncher'

function generateProps(overrides = {}) {
  return {
    title: 'Modal Title',
    tool: {placements: {course_assignments_menu: {}}},
    isOpen: false,
    onRequestClose: () => {},
    contextType: 'course',
    contextId: 5,
    launchType: 'course_assignments_menu',
    ...overrides,
  }
}

describe('ExternalToolModalLauncher', () => {
  beforeEach(() => {
    ENV.LTI_LAUNCH_FRAME_ALLOWANCES = ['midi', 'media']
  })

  afterEach(() => {
    ENV.LTI_LAUNCH_FRAME_ALLOWANCES = []
  })

  it('renders a Modal', () => {
    const {getByText} = render(<ExternalToolModalLauncher {...generateProps()} isOpen={true} />)
    expect(getByText('Modal Title')).toBeInTheDocument()
  })

  it('launch with custom height & width', () => {
    const height = 111
    const width = 222

    const overrides = {
      tool: {placements: {course_assignments_menu: {launch_width: width, launch_height: height}}},
      isOpen: true,
    }

    const {getByTitle} = render(<ExternalToolModalLauncher {...generateProps(overrides)} />)

    const iframe = getByTitle('Modal Title')
    expect(iframe).toHaveStyle(`width: ${width}px`)
    expect(iframe).toHaveStyle(`height: ${height}px`)
  })

  describe('handling external content events', () => {
    const origEnv = {...window.ENV}
    const origin = 'http://example.com'
    beforeAll(() => (window.ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN = origin))
    afterAll(() => (window.ENV = origEnv))
    const sendPostMessage = (data: any) =>
      fireEvent(window, new MessageEvent('message', {data, origin}))

    test('invokes onRequestClose prop when window receives externalContentReady event', async () => {
      const onRequestCloseMock = jest.fn()
      const props = generateProps({onRequestClose: onRequestCloseMock})

      render(<ExternalToolModalLauncher {...props} />)

      sendPostMessage({
        subject: 'externalContentReady',
        service: 'external_tool_redirect',
        contentItems: [],
      })
      expect(onRequestCloseMock).toHaveBeenCalledTimes(1)
    })

    test('invokes onRequestClose prop when window receives externalContentCancel event', () => {
      const onRequestCloseMock = jest.fn()
      const props = generateProps({onRequestClose: onRequestCloseMock})

      render(<ExternalToolModalLauncher {...props} />)

      sendPostMessage({subject: 'externalContentCancel'})

      expect(onRequestCloseMock).toHaveBeenCalledTimes(1)
    })
  })

  test('sets the iframe allowances', async () => {
    const {getByTitle} = render(<ExternalToolModalLauncher {...generateProps({isOpen: true})} />)
    const iframe = getByTitle('Modal Title')
    await waitFor(() =>
      expect(iframe).toHaveAttribute('allow', ENV.LTI_LAUNCH_FRAME_ALLOWANCES.join('; '))
    )
  })

  test('sets the iframe data-lti-launch attribute', () => {
    const {getByTitle} = render(<ExternalToolModalLauncher {...generateProps({isOpen: true})} />)
    const iframe = getByTitle('Modal Title')
    expect(iframe).toHaveAttribute('data-lti-launch', 'true')
  })
})

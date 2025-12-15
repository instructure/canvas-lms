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

/**
 * This test is separated from ExternalToolModalLauncher.test.tsx because
 * monitorLtiMessages() adds a global event listener that persists across tests
 * and can cause flaky failures when running with other tests due to:
 * 1. Module-level hasListener flag being shared across tests in the same worker
 * 2. jsdom limitations with cross-iframe postMessage causing unhandled errors
 */

import {fireEvent, render, waitFor} from '@testing-library/react'
import ExternalToolModalLauncher from '../ExternalToolModalLauncher'
import {monitorLtiMessages} from '@canvas/lti/jquery/messages'

function generateProps(overrides = {}) {
  return {
    title: 'Modal Title',
    tool: {placements: {course_assignments_menu: {}}, definition_id: '1'},
    isOpen: false,
    onRequestClose: () => {},
    contextType: 'course',
    contextId: 5,
    launchType: 'course_assignments_menu',
    ...overrides,
  }
}

describe('ExternalToolModalLauncher lti.close', () => {
  const origin = 'http://example.com'
  const sendPostMessage = (data: any, source?: Window | null) =>
    fireEvent(window, new MessageEvent('message', {data, origin, source: source || window}))

  beforeEach(() => {
    ENV.LTI_LAUNCH_FRAME_ALLOWANCES = ['midi', 'media']
  })

  afterEach(() => {
    ENV.LTI_LAUNCH_FRAME_ALLOWANCES = []
  })

  it('calls onRequestClose when tool sends lti.close event', async () => {
    monitorLtiMessages()

    const onRequestCloseMock = vi.fn()
    const {getByTitle} = render(
      <ExternalToolModalLauncher
        {...generateProps({onRequestClose: onRequestCloseMock, isOpen: true})}
      />,
    )

    const iframe = getByTitle('Modal Title') as HTMLIFrameElement
    sendPostMessage({subject: 'lti.close'}, iframe.contentWindow)

    await waitFor(() => {
      expect(onRequestCloseMock).toHaveBeenCalled()
    })
  })
})

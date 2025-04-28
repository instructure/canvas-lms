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

import {fireEvent, render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
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

describe('ExternalToolModalLauncher', () => {
  const origin = 'http://example.com'
  const sendPostMessage = (data: any) =>
    fireEvent(window, new MessageEvent('message', {data, origin, source: window}))

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
    beforeAll(() => (window.ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN = origin))
    afterAll(() => (window.ENV = origEnv))

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

    test('invokes onDeepLinkingResponse prop when window receives externalContentCancel event', () => {
      const onDeepLinkingResponseMock = jest.fn()
      const props = generateProps({onDeepLinkingResponse: onDeepLinkingResponseMock})

      render(<ExternalToolModalLauncher {...props} />)

      sendPostMessage({subject: 'LtiDeepLinkingResponse'})

      expect(onDeepLinkingResponseMock).toHaveBeenCalledTimes(1)
    })
  })

  describe('onClose behavior', () => {
    it('calls onRequestClose when clicking a button element', async () => {
      const onRequestCloseMock = jest.fn()
      const {getByText} = render(
        <ExternalToolModalLauncher
          {...generateProps({onRequestClose: onRequestCloseMock, isOpen: true})}
        />,
      )

      const closeButton = getByText('Close').closest('button')
      if (!closeButton) throw new Error('No close button found')
      await userEvent.click(closeButton)

      expect(onRequestCloseMock).toHaveBeenCalledTimes(1)
    })

    it('does not call onRequestClose when clicking outside the diaglog', async () => {
      const onRequestCloseMock = jest.fn()
      const {getByRole} = render(
        <ExternalToolModalLauncher
          {...generateProps({onRequestClose: onRequestCloseMock, isOpen: true})}
        />,
      )

      const backdrop = getByRole('dialog').parentElement
      if (!backdrop) throw new Error('No div element found')
      await userEvent.click(backdrop)

      expect(onRequestCloseMock).not.toHaveBeenCalled()
    })

    it('calls onRequestClose when tool sends lti.close event', async () => {
      monitorLtiMessages()

      const onRequestCloseMock = jest.fn()
      render(
        <ExternalToolModalLauncher
          {...generateProps({onRequestClose: onRequestCloseMock, isOpen: true})}
        />,
      )

      sendPostMessage({subject: 'lti.close'})

      await waitFor(() => {
        expect(onRequestCloseMock).toHaveBeenCalled()
      })
    })
  })

  test('sets the iframe allowances', async () => {
    const {getByTitle} = render(<ExternalToolModalLauncher {...generateProps({isOpen: true})} />)
    const iframe = getByTitle('Modal Title')
    await waitFor(() =>
      expect(iframe).toHaveAttribute('allow', ENV.LTI_LAUNCH_FRAME_ALLOWANCES.join('; ')),
    )
  })

  test('sets the iframe data-lti-launch attribute', () => {
    const {getByTitle} = render(<ExternalToolModalLauncher {...generateProps({isOpen: true})} />)
    const iframe = getByTitle('Modal Title')
    expect(iframe).toHaveAttribute('data-lti-launch', 'true')
  })

  describe('iframe get correct src', () => {
    test('without resourceSelection param', () => {
      const props = generateProps({isOpen: true})
      const {getByTitle} = render(<ExternalToolModalLauncher {...props} />)
      const iframe = getByTitle(props.title)
      expect(iframe).toHaveAttribute(
        'src',
        `/courses/${props.contextId}/external_tools/${props.tool.definition_id}?display=borderless&launch_type=${props.launchType}`,
      )
    })

    test('with resourceSelection param', () => {
      const props = generateProps({isOpen: true, resourceSelection: true})
      const {getByTitle} = render(<ExternalToolModalLauncher {...props} />)
      const iframe = getByTitle(props.title)
      expect(iframe).toHaveAttribute(
        'src',
        `/courses/${props.contextId}/external_tools/${props.tool.definition_id}/resource_selection?display=borderless&launch_type=${props.launchType}`,
      )
    })

    test('with simplified props', () => {
      const directSrc = '/asset_processors/123/launch'
      const customWidth = 850
      const customHeight = 550
      const customTitle = 'Direct Src Modal'

      const {getByTitle} = render(
        <ExternalToolModalLauncher
          title={customTitle}
          isOpen={true}
          iframeSrc={directSrc}
          onRequestClose={() => {}}
          width={customWidth}
          height={customHeight}
        />,
      )

      const iframe = getByTitle(customTitle)

      // Verify all simplified props are correctly applied
      expect(iframe).toHaveAttribute('src', directSrc)
      expect(iframe).toHaveStyle(`width: ${customWidth}px`)
      expect(iframe).toHaveStyle(`height: ${customHeight}px`)
      expect(iframe).toHaveAttribute('title', customTitle)
      expect(iframe).toHaveAttribute('data-lti-launch', 'true')
    })
  })
})

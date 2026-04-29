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
import {render, screen, waitFor} from '@testing-library/react'
import StudentAssetReportModalWrapper, {
  ASSET_REPORT_MODAL_EVENT,
  sendOpenAssetReportModalMessage,
} from '../StudentAssetReportModalWrapper'

// Mock the modal component
vi.mock('../StudentLtiAssetReportModal', () => ({
  default: function MockStudentLtiAssetReportModal(props: any) {
    return (
      <div data-testid="student-asset-report-modal">
        <div data-testid="modal-assignment-name">{props.assignmentName}</div>
        <div data-testid="modal-attempt">{props.attempt}</div>
        <div data-testid="modal-submission-type">{props.submissionType}</div>
        <button data-testid="close-modal" onClick={props.onClose}>
          Close
        </button>
      </div>
    )
  },
}))

describe.skip('StudentAssetReportModalWrapper', () => {
  const mockData = {
    assignmentName: 'Test Assignment',
    attempt: 1,
    submissionType: 'online_upload',
    assetProcessors: [
      {
        _id: 'processor1',
        externalTool: {name: 'Test Processor'},
      },
    ],
    reports: [
      {
        _id: 'report1',
        asset: {attachmentId: '123'},
        status: 'completed',
      },
    ],
  }

  let consoleSpy: any

  beforeEach(() => {
    // Mock console.warn to test origin validation
    consoleSpy = vi.spyOn(console, 'warn').mockImplementation(() => {})
  })

  afterEach(() => {
    consoleSpy.mockRestore()
    // Clean up any event listeners
    window.removeEventListener('message', expect.any(Function))
  })

  it('does not render modal initially', () => {
    render(<StudentAssetReportModalWrapper />)
    expect(screen.queryByTestId('student-asset-report-modal')).not.toBeInTheDocument()
  })

  it('renders modal when valid postMessage is received', async () => {
    render(<StudentAssetReportModalWrapper />)

    // Create and dispatch a custom MessageEvent
    const event = new MessageEvent('message', {
      data: {
        type: ASSET_REPORT_MODAL_EVENT,
        ...mockData,
      },
      origin: window.location.origin,
    })

    window.dispatchEvent(event)

    await waitFor(() => {
      expect(screen.getByTestId('student-asset-report-modal')).toBeInTheDocument()
    })

    expect(screen.getByTestId('modal-assignment-name')).toHaveTextContent('Test Assignment')
    expect(screen.getByTestId('modal-attempt')).toHaveTextContent('1')
    expect(screen.getByTestId('modal-submission-type')).toHaveTextContent('online_upload')
  })

  it('closes modal when onClose is called', async () => {
    render(<StudentAssetReportModalWrapper />)

    // Create and dispatch a custom MessageEvent to open modal
    const event = new MessageEvent('message', {
      data: {
        type: ASSET_REPORT_MODAL_EVENT,
        ...mockData,
      },
      origin: window.location.origin,
    })

    window.dispatchEvent(event)

    await waitFor(() => {
      expect(screen.getByTestId('student-asset-report-modal')).toBeInTheDocument()
    })

    // Click close button
    screen.getByTestId('close-modal').click()

    await waitFor(() => {
      expect(screen.queryByTestId('student-asset-report-modal')).not.toBeInTheDocument()
    })
  })

  it('ignores messages from different origins', async () => {
    render(<StudentAssetReportModalWrapper />)

    // Create a custom event with different origin
    const event = new MessageEvent('message', {
      data: {
        type: ASSET_REPORT_MODAL_EVENT,
        ...mockData,
      },
      origin: 'https://different-origin.com',
    })

    window.dispatchEvent(event)

    await waitFor(() => {
      expect(consoleSpy).toHaveBeenCalledWith(
        'Rejected message from different origin:',
        'https://different-origin.com',
      )
    })

    expect(screen.queryByTestId('student-asset-report-modal')).not.toBeInTheDocument()
  })

  it('ignores messages with wrong type', async () => {
    render(<StudentAssetReportModalWrapper />)

    const event = new MessageEvent('message', {
      data: {
        type: 'wrong-event-type',
        ...mockData,
      },
      origin: window.location.origin,
    })

    window.dispatchEvent(event)

    // Wait a bit to ensure no modal appears
    await new Promise(resolve => setTimeout(resolve, 100))

    expect(screen.queryByTestId('student-asset-report-modal')).not.toBeInTheDocument()
  })

  it('handles messages with no data', async () => {
    render(<StudentAssetReportModalWrapper />)

    const event = new MessageEvent('message', {
      data: null,
      origin: window.location.origin,
    })

    window.dispatchEvent(event)

    // Wait a bit to ensure no modal appears
    await new Promise(resolve => setTimeout(resolve, 100))

    expect(screen.queryByTestId('student-asset-report-modal')).not.toBeInTheDocument()
  })

  it('cleans up event listener on unmount', () => {
    const addEventListenerSpy = vi.spyOn(window, 'addEventListener')
    const removeEventListenerSpy = vi.spyOn(window, 'removeEventListener')

    const {unmount} = render(<StudentAssetReportModalWrapper />)

    expect(addEventListenerSpy).toHaveBeenCalledWith('message', expect.any(Function))

    unmount()

    expect(removeEventListenerSpy).toHaveBeenCalledWith('message', expect.any(Function))

    addEventListenerSpy.mockRestore()
    removeEventListenerSpy.mockRestore()
  })
})

describe('sendOpenAssetReportModalMessage', () => {
  let postMessageSpy: any

  beforeEach(() => {
    postMessageSpy = vi.spyOn(window.parent, 'postMessage').mockImplementation(() => {})
  })

  afterEach(() => {
    postMessageSpy.mockRestore()
  })

  it('sends postMessage to parent with correct data and origin', () => {
    const mockData = {
      assignmentName: 'Test Assignment',
      attempt: 2,
      submissionType: 'online_text_entry' as const,
      assetProcessors: [],
      reports: [],
    }

    sendOpenAssetReportModalMessage(mockData)

    expect(postMessageSpy).toHaveBeenCalledWith(
      {
        type: ASSET_REPORT_MODAL_EVENT,
        ...mockData,
      },
      window.location.origin,
    )
  })
})

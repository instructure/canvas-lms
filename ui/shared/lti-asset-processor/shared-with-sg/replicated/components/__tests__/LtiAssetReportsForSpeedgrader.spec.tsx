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

// This import needs to be first to ensure that the mocked dependencies are set up before any other imports.

import {fireEvent, screen} from '@testing-library/react'
import {
  mockUseLtiAssetProcessors,
  mockUseLtiAssetReports,
} from '../../../__tests__/mockedDependenciesShims'
import {renderComponent} from '../../../__tests__/renderingShims'
import {describe, expect, fn, it} from '../../../__tests__/testPlatformShims'
import {useLtiAssetProcessors, useLtiAssetReports} from '../../../dependenciesShims'
import {defaultGetLtiAssetProcessorsResult} from '../../__fixtures__/default/ltiAssetProcessors'
import {
  defaultGetLtiAssetReportsResult,
  makeMockReport,
} from '../../__fixtures__/default/ltiAssetReports'
import type {LtiAssetReport} from '../../types/LtiAssetReports'
import {LtiAssetReportsForSpeedgrader} from '../LtiAssetReportsForSpeedgrader'

describe('LtiAssetReportsForSpeedgrader', () => {
  it('renders without crashing', () => {
    mockUseLtiAssetProcessors(defaultGetLtiAssetProcessorsResult)
    mockUseLtiAssetReports(
      defaultGetLtiAssetReportsResult({
        attachmentId: '1234',
      }),
    )

    const component = (
      <LtiAssetReportsForSpeedgrader
        assignmentId="123"
        attempt={1}
        submissionType="online_upload"
        attachments={[{_id: '1234', displayName: 'test.txt'}]}
        studentUserId="456"
        studentAnonymousId={null}
      />
    )
    const {queryByText} = renderComponent(component)

    expect(queryByText('My OK Report')).toBeInTheDocument()

    expect(useLtiAssetProcessors).toHaveBeenCalledWith({
      assignmentId: '123',
    })
    expect(useLtiAssetReports).toHaveBeenCalledWith(
      {
        assignmentId: '123',
        studentUserId: '456',
        studentAnonymousId: null,
      },
      {cancel: false},
    )

    expect(queryByText('Resubmit All Files')).toBeInTheDocument()
  })

  describe('for discussion_topic submissions', () => {
    function makeMockDiscussionReport(params: Partial<LtiAssetReport> = {}): LtiAssetReport {
      return makeMockReport({
        title: 'Discussion Report',
        processorId: '1000',
        asset: {
          discussionEntryVersion: {
            _id: 'entry_123',
            createdAt: '2025-01-15T16:45:00Z',
            messageIntro: 'This is a test discussion entry message',
          },
        },
        priority: 0,
        ...params,
      })
    }

    it('renders status in AllReportsCard', () => {
      mockUseLtiAssetProcessors(defaultGetLtiAssetProcessorsResult)
      const multipleReports = [makeMockDiscussionReport(), makeMockDiscussionReport({priority: 5})]
      mockUseLtiAssetReports({
        submission: {
          ltiAssetReportsConnection: {
            nodes: multipleReports,
          },
        },
      })

      renderComponent(
        <LtiAssetReportsForSpeedgrader
          assignmentId="123"
          attempt={1}
          submissionType="discussion_topic"
          attachments={[{_id: '1234', displayName: 'test.txt'}]}
          studentUserId="456"
          studentAnonymousId={null}
        />,
      )

      expect(screen.getByText('All comments')).toBeInTheDocument()
      expect(screen.getByText('Reports')).toBeInTheDocument()
      expect(screen.getByText('View reports')).toBeInTheDocument()
      expect(screen.getByText('Please review')).toBeInTheDocument()
    })

    it('opens modal when View reports button is clicked', () => {
      mockUseLtiAssetProcessors(defaultGetLtiAssetProcessorsResult)
      const multipleReports = [
        makeMockDiscussionReport({title: 'myreport1'}),
        makeMockDiscussionReport(),
      ]
      mockUseLtiAssetReports({
        submission: {
          ltiAssetReportsConnection: {
            nodes: multipleReports,
          },
        },
      })

      renderComponent(
        <LtiAssetReportsForSpeedgrader
          assignmentId="123"
          attempt={1}
          submissionType="discussion_topic"
          attachments={[{_id: '1234', displayName: 'test.txt'}]}
          studentUserId="456"
          studentAnonymousId={null}
        />,
      )

      // expect myreport1 not in Document:
      expect(screen.queryByText('myreport1')).not.toBeInTheDocument()

      const viewReportsButton = screen.getByText('View reports')
      fireEvent.click(viewReportsButton)

      expect(screen.getByText('myreport1')).toBeInTheDocument()
    })

    it('shows Resubmit All Replies button', () => {
      mockUseLtiAssetProcessors(defaultGetLtiAssetProcessorsResult)
      const multipleReports = [
        makeMockDiscussionReport({resubmitAvailable: true}),
        makeMockDiscussionReport({priority: 5}),
      ]
      mockUseLtiAssetReports({
        submission: {
          ltiAssetReportsConnection: {
            nodes: multipleReports,
          },
        },
      })

      renderComponent(
        <LtiAssetReportsForSpeedgrader
          assignmentId="123"
          attempt={1}
          submissionType="discussion_topic"
          attachments={[]}
          studentUserId="456"
          studentAnonymousId={null}
        />,
      )

      expect(screen.getByText('Resubmit All Replies')).toBeInTheDocument()
    })

    it('shows Resubmit All Replies button when there are no reports', () => {
      mockUseLtiAssetProcessors(defaultGetLtiAssetProcessorsResult)
      const reports: LtiAssetReport[] = []
      mockUseLtiAssetReports({
        submission: {
          ltiAssetReportsConnection: {
            nodes: reports,
          },
        },
      })

      renderComponent(
        <LtiAssetReportsForSpeedgrader
          assignmentId="123"
          attempt={1}
          submissionType="discussion_topic"
          attachments={[]}
          studentUserId="456"
          studentAnonymousId={null}
        />,
      )

      expect(screen.getByText('Resubmit All Replies')).toBeInTheDocument()
    })

    it('hides Resubmit All Replies button when studentIdForResubmission is not provided', () => {
      mockUseLtiAssetProcessors(defaultGetLtiAssetProcessorsResult)
      const multipleReports = [
        makeMockDiscussionReport({resubmitAvailable: true}),
        makeMockDiscussionReport({priority: 5}),
      ]
      mockUseLtiAssetReports({
        submission: {
          ltiAssetReportsConnection: {
            nodes: multipleReports,
          },
        },
      })

      renderComponent(
        <LtiAssetReportsForSpeedgrader
          assignmentId="123"
          attempt={1}
          submissionType="discussion_topic"
          attachments={[]}
          studentUserId={null}
          studentAnonymousId={null}
        />,
      )

      expect(screen.queryByText('Resubmit All Replies')).not.toBeInTheDocument()
    })
  })

  describe('for non-discussion submissions', () => {
    it('renders LtiAssetReports directly for online_upload with multiple reports', () => {
      mockUseLtiAssetProcessors(defaultGetLtiAssetProcessorsResult)
      const multipleReports = [
        makeMockReport({
          title: 'Report 1',
          processorId: '1000',
          asset: {attachmentId: '1234'},
          _id: '1',
          priority: 0,
        }),
        makeMockReport({
          title: 'Report 2',
          processorId: '1000',
          asset: {attachmentId: '1234'},
          _id: '2',
          priority: 0,
        }),
      ]
      mockUseLtiAssetReports({
        submission: {
          ltiAssetReportsConnection: {
            nodes: multipleReports,
          },
        },
      })

      renderComponent(
        <LtiAssetReportsForSpeedgrader
          assignmentId="123"
          attempt={1}
          submissionType="online_upload"
          attachments={[{_id: '1234', displayName: 'test.txt'}]}
          studentUserId="456"
          studentAnonymousId={null}
        />,
      )

      // Should not show AllReportsCard for non-discussion submissions
      expect(screen.queryByText('All comments')).not.toBeInTheDocument()
      expect(screen.queryByText('View reports')).not.toBeInTheDocument()
    })

    it('renders LtiAssetReports directly for online_text_entry', () => {
      mockUseLtiAssetProcessors(defaultGetLtiAssetProcessorsResult)
      const singleReport = [
        makeMockReport({
          title: 'My OK Report',
          processorId: '1000',
          asset: {submissionAttempt: 1},
        }),
      ]
      mockUseLtiAssetReports({
        submission: {
          ltiAssetReportsConnection: {
            nodes: singleReport,
          },
        },
      })

      renderComponent(
        <LtiAssetReportsForSpeedgrader
          assignmentId="123"
          attempt={1}
          submissionType="online_text_entry"
          attachments={[{_id: '1234', displayName: 'test.txt'}]}
          studentUserId="456"
          studentAnonymousId={null}
        />,
      )

      expect(screen.queryByText('All comments')).not.toBeInTheDocument()
      expect(screen.getByText('My OK Report')).toBeInTheDocument()
    })
  })

  describe('collapsible behavior', () => {
    it("renders with header 'Document processor reports'", () => {
      mockUseLtiAssetProcessors(defaultGetLtiAssetProcessorsResult)
      mockUseLtiAssetReports(
        defaultGetLtiAssetReportsResult({
          attachmentId: '1234',
        }),
      )

      renderComponent(
        <LtiAssetReportsForSpeedgrader
          assignmentId="123"
          attempt={1}
          submissionType="online_upload"
          attachments={[{_id: '1234', displayName: 'test.txt'}]}
          studentUserId="456"
          studentAnonymousId={null}
        />,
      )

      expect(screen.getByTestId('comments-label')).toHaveTextContent('Document processor reports')
    })

    it('passes expanded prop to ToggleDetails', () => {
      mockUseLtiAssetProcessors(defaultGetLtiAssetProcessorsResult)
      mockUseLtiAssetReports(
        defaultGetLtiAssetReportsResult({
          attachmentId: '1234',
        }),
      )

      const onToggleExpanded = fn()
      const {rerender} = renderComponent(
        <LtiAssetReportsForSpeedgrader
          assignmentId="123"
          attempt={1}
          submissionType="online_upload"
          attachments={[{_id: '1234', displayName: 'test.txt'}]}
          studentUserId="456"
          studentAnonymousId={null}
          expanded={true}
          onToggleExpanded={onToggleExpanded}
        />,
      )

      // When expanded=true, content should be visible
      expect(screen.getByText('My OK Report')).toBeInTheDocument()

      rerender(
        <LtiAssetReportsForSpeedgrader
          assignmentId="123"
          attempt={1}
          submissionType="online_upload"
          attachments={[{_id: '1234', displayName: 'test.txt'}]}
          studentUserId="456"
          studentAnonymousId={null}
          expanded={false}
          onToggleExpanded={onToggleExpanded}
        />,
      )

      // When expanded=false, content should not be visible
      expect(screen.queryByText('My OK Report')).not.toBeInTheDocument()
    })

    it('calls onToggleExpanded when ToggleDetails is toggled', () => {
      mockUseLtiAssetProcessors(defaultGetLtiAssetProcessorsResult)
      mockUseLtiAssetReports(
        defaultGetLtiAssetReportsResult({
          attachmentId: '1234',
        }),
      )

      const onToggleExpanded = fn()

      renderComponent(
        <LtiAssetReportsForSpeedgrader
          assignmentId="123"
          attempt={1}
          submissionType="online_upload"
          attachments={[{_id: '1234', displayName: 'test.txt'}]}
          studentUserId="456"
          studentAnonymousId={null}
          expanded={false}
          onToggleExpanded={onToggleExpanded}
        />,
      )

      // Click the toggle button to expand
      const toggleButton = screen.getByRole('button', {
        name: 'Document processor reports',
      })
      fireEvent.click(toggleButton)

      expect(onToggleExpanded).toHaveBeenCalledWith(expect.any(Object), true)
    })
  })
})

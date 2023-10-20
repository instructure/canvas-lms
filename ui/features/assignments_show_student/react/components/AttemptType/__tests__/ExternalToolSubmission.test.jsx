/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {fireEvent, render} from '@testing-library/react'
import React from 'react'
import {SubmissionMocks} from '@canvas/assignments/graphql/student/Submission'

import ExternalToolSubmission from '../ExternalToolSubmission'

describe('ExternalToolSubmission', () => {
  const windowOrigin = window.origin || document.origin // TODO: JSDOM v16 Upgrade

  let oldEnv
  let tool

  beforeEach(() => {
    oldEnv = ENV

    ENV = {
      ASSIGNMENT_ID: '200',
      DEEP_LINKING_POST_MESSAGE_ORIGIN: windowOrigin,
      COURSE_ID: '100',
    }

    tool = {name: 'some external tool', _id: '1'}
  })

  afterEach(() => {
    ENV = oldEnv
  })

  describe('when the submission has been submitted', () => {
    it('shows an iframe with the submitted URL', () => {
      const submission = SubmissionMocks.basicLtiLaunchSubmitted
      const {getByTestId} = render(<ExternalToolSubmission submission={submission} tool={tool} />)

      const iframe = getByTestId('lti-launch-frame')
      expect(iframe).toBeInTheDocument()
      expect(iframe.src).toBe(
        'http://localhost/courses/100/external_tools/retrieve?assignment_id=200&display=borderless&resource_link_lookup_uuid=some_uuid&url=%2Fsubmitted-lti-launch'
      )
    })
  })

  describe('when a draft exists with content for this external tool', () => {
    it('shows the URL and content using the values specified in the draft', () => {
      const submission = {...SubmissionMocks.basicLtiLaunchReadyToSubmit}
      const {getByTestId, getByText} = render(
        <ExternalToolSubmission submission={submission} tool={tool} />
      )

      const iframe = getByTestId('lti-launch-frame')
      expect(iframe).toBeInTheDocument()
      expect(iframe.src).toBe(
        'http://localhost/courses/100/external_tools/retrieve?assignment_id=200&display=borderless&resource_link_lookup_uuid=some_uuid&url=%2Flti-launch'
      )

      expect(getByText(/Website URL:\s*\/lti-launch/)).toBeInTheDocument()
    })

    it('shows the original resource-selection launch frame if the user clicks the "Change" button', () => {
      const submission = SubmissionMocks.basicLtiLaunchReadyToSubmit
      const {getByRole, getByTestId} = render(
        <ExternalToolSubmission submission={submission} tool={tool} />
      )

      const changeButton = getByRole('button', {name: /Change/})
      fireEvent.click(changeButton)

      const iframe = getByTestId('lti-launch-frame')
      expect(iframe).toBeInTheDocument()
      expect(iframe.src).toBe(
        'http://localhost/courses/100/external_tools/1/resource_selection?launch_type=homework_submission&assignment_id=200'
      )
    })
  })

  describe('when a draft exists with content for a different external tool', () => {
    it('shows the resource-selection launch frame for the selected tool', () => {
      const otherTool = {name: 'some other external tool', _id: '2'}
      const submission = SubmissionMocks.basicLtiLaunchReadyToSubmit
      const {getByTestId} = render(
        <ExternalToolSubmission submission={submission} tool={otherTool} />
      )

      const iframe = getByTestId('lti-launch-frame')
      expect(iframe).toBeInTheDocument()
      expect(iframe.src).toBe(
        'http://localhost/courses/100/external_tools/2/resource_selection?launch_type=homework_submission&assignment_id=200'
      )
    })
  })

  describe('when nothing has been submitted and no draft is present', () => {
    it('shows the resource-selection launch frame for the current tool', () => {
      const submission = {state: 'unsubmitted'}
      const {getByTestId} = render(<ExternalToolSubmission submission={submission} tool={tool} />)

      const iframe = getByTestId('lti-launch-frame')
      expect(iframe).toBeInTheDocument()
      expect(iframe.src).toBe(
        'http://localhost/courses/100/external_tools/1/resource_selection?launch_type=homework_submission&assignment_id=200'
      )
    })
  })

  describe('when receving a message event', () => {
    let createSubmissionDraft
    let onFileUploadRequested

    beforeEach(() => {
      createSubmissionDraft = jest.fn()
      onFileUploadRequested = jest.fn()
    })

    function postMessage(subject, contents) {
      const data = {
        subject,
        ...contents,
      }
      fireEvent(window, new MessageEvent('message', {origin: windowOrigin, data}))
    }

    const renderComponent = submission =>
      render(
        <ExternalToolSubmission
          createSubmissionDraft={createSubmissionDraft}
          onFileUploadRequested={onFileUploadRequested}
          submission={submission}
          tool={tool}
        />
      )

    it('does nothing if the submission is already submitted', () => {
      const {getByTestId} = renderComponent(SubmissionMocks.basicLtiLaunchSubmitted)

      postMessage('A2ExternalContentReady', {
        content_items: [{'@type': 'FileItem', url: '/another-url'}],
      })
      const iframe = getByTestId('lti-launch-frame')
      expect(iframe.src).toContain('%2Fsubmitted-lti-launch')
    })

    describe('when not yet submitted', () => {
      it('ignores events that are not A2ExternalContentReady or LtiDeepLinkingResponse', () => {
        renderComponent(SubmissionMocks.basicLtiLaunchReadyToSubmit)

        postMessage('A2ExternalContentAbsolutelyNotReady', {
          content_items: [{'@type': 'FileItem', url: '/another-lti-launch'}],
        })
        expect(onFileUploadRequested).not.toHaveBeenCalled()
      })

      it('ignores events with an origin different from the one specified in ENV', () => {
        window.ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN = 'http://evil-site-origin'

        postMessage('A2ExternalContentReady', {
          content_items: [{'@type': 'FileItem', url: '/another-lti-launch'}],
        })
        expect(onFileUploadRequested).not.toHaveBeenCalled()
      })

      it('does nothing if the message contains no content items', () => {
        renderComponent(SubmissionMocks.basicLtiLaunchReadyToSubmit)
        postMessage('A2ExternalContentReady', {})

        expect(onFileUploadRequested).not.toHaveBeenCalled()
        expect(createSubmissionDraft).not.toHaveBeenCalled()
      })
    })

    describe('handling messages', () => {
      function testReceivingFileContent(contentItem) {
        const submission = SubmissionMocks.basicLtiLaunchReadyToSubmit
        renderComponent(submission)

        postMessage('A2ExternalContentReady', {content_items: [contentItem]})
        expect(onFileUploadRequested).toHaveBeenCalledWith({files: [contentItem]})
        expect(createSubmissionDraft).not.toHaveBeenCalled()
      }

      function testReceivingLinkContent(contentItem) {
        const submission = SubmissionMocks.basicLtiLaunchReadyToSubmit
        const {getByRole} = render(
          <ExternalToolSubmission
            createSubmissionDraft={createSubmissionDraft}
            onFileUploadRequested={onFileUploadRequested}
            submission={submission}
            tool={tool}
          />
        )

        postMessage('A2ExternalContentReady', {content_items: [contentItem]})

        expect(createSubmissionDraft).toHaveBeenCalledWith({
          variables: {
            activeSubmissionType: 'basic_lti_launch',
            attempt: submission.attempt || 1,
            externalToolId: tool._id,
            id: submission.id,
            ltiLaunchUrl: contentItem.url,
            resourceLinkLookupUuid: contentItem.lookup_uuid,
          },
        })
        expect(onFileUploadRequested).not.toHaveBeenCalled()

        expect(getByRole('button', {name: /Change/})).toBeInTheDocument()
      }

      it('calls the onFileUploadRequested prop when the @type property is "FileItem"', () => {
        testReceivingFileContent({
          '@type': 'FileItem',
          name: 'some file',
          url: '/some-file',
          mediaType: '',
        })
      })

      it('calls the onFileUploadRequested prop when the type property is "file"', () => {
        testReceivingFileContent({
          name: 'some file',
          type: 'file',
          url: '/some-file',
          mediaType: '',
        })
      })

      it('saves a draft when the @type property is "LtiLinkItem"', () => {
        testReceivingLinkContent({
          '@type': 'LtiLinkItem',
          lookup_uuid: 'some-uuid',
          name: 'some link',
          url: '/some-url',
        })
      })

      it('saves a draft when the type property is "ltiLink"', () => {
        testReceivingLinkContent({
          name: 'some link',
          lookup_uuid: 'some-uuid',
          type: 'ltiLink',
          url: '/some-url',
        })
      })
    })
  })
})

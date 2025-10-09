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
import ReactDOM from 'react-dom'
import {renderLtiAssetReports} from '../speed_grader'
import {Attachment, HistoricalSubmission, Submission} from '../speed_grader.d'
import {LtiAssetReportsForSpeedgraderProps} from '@canvas/lti-asset-processor/shared-with-sg/replicated/components/LtiAssetReportsForSpeedgrader'

const SPEED_GRADER_LTI_ASSET_REPORTS_MOUNT_POINT = 'speed_grader_lti_asset_reports_mount_point'

jest.mock('react-dom', () => ({
  render: jest.fn(),
  unmountComponentAtNode: jest.fn(),
}))

describe('renderLtiAssetReports', () => {
  let mountPoint: HTMLElement

  beforeEach(() => {
    mountPoint = document.createElement('div')
    mountPoint.id = SPEED_GRADER_LTI_ASSET_REPORTS_MOUNT_POINT
    document.body.appendChild(mountPoint)
    jest.clearAllMocks()
    // @ts-expect-error
    window.ENV = {FEATURES: {lti_asset_processor: true}}
  })

  afterEach(() => {
    document.body.removeChild(mountPoint)
  })

  const submission: Submission = {
    assignment_id: '12',
    user_id: '123',
  }

  const jsonData = {
    lti_asset_processors: [],
  }

  const attachment: Attachment = {
    canvadoc_url: null,
    comment_id: null,
    content_type: '',
    created_at: '',
    display_name: 'student-essay-doc',
    filename: '',
    id: '456',
    mime_class: '',
    provisional_canvadoc_url: null,
    provisional_crocodoc_url: null,
    submitter_id: '',
    updated_at: '',
    upload_status: 'pending',
    url: null,
    view_inline_ping_url: null,
    viewed_at: '',
    word_count: 0,
    workflow_state: 'pending_upload',
  }

  it('should render when there is a submission', () => {
    const historicalSubmission: HistoricalSubmission = {
      attempt: 1,
      submission_type: 'online_text_entry',
      versioned_attachments: [{attachment}],
    }
    renderLtiAssetReports(submission, historicalSubmission)
    expect(ReactDOM.render).toHaveBeenCalled()
    expect(ReactDOM.unmountComponentAtNode).not.toHaveBeenCalled()

    const component = (ReactDOM.render as jest.Mock).mock.calls[0][0] as React.Component
    const expected: LtiAssetReportsForSpeedgraderProps = {
      assignmentId: '12',
      attachments: [{_id: '456', displayName: 'student-essay-doc'}],
      attempt: 1,
      studentAnonymousId: null,
      studentUserId: '123',
      submissionType: 'online_text_entry',
    }
    expect(component.props).toEqual(expected)
  })

  it('should unmount when there is no submission', () => {
    const historicalSubmission = {
      attempt: null,
      submission_type: null,
    }
    // @ts-expect-error
    renderLtiAssetReports(submission, historicalSubmission, jsonData)
    expect(ReactDOM.render).not.toHaveBeenCalled()
    expect(ReactDOM.unmountComponentAtNode).toHaveBeenCalledWith(mountPoint)
  })
})

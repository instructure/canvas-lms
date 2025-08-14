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

  const submission = {
    user_id: '1',
    lti_asset_reports: [],
  }
  const jsonData = {
    lti_asset_processors: [],
  }

  it('should render when there is a submission', () => {
    const historicalSubmission = {
      attempt: 1,
      submission_type: 'online_text_entry',
      versioned_attachments: [],
    }
    // @ts-expect-error
    renderLtiAssetReports(submission, historicalSubmission, jsonData)
    expect(ReactDOM.render).toHaveBeenCalled()
    expect(ReactDOM.unmountComponentAtNode).not.toHaveBeenCalled()
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

  it('should unmount when submission_type is not online_text_entry or online_upload', () => {
    const historicalSubmission = {
      attempt: 1,
      submission_type: 'basic_lti_launch',
    }
    // @ts-expect-error
    renderLtiAssetReports(submission, historicalSubmission, jsonData)
    expect(ReactDOM.render).not.toHaveBeenCalled()
    expect(ReactDOM.unmountComponentAtNode).toHaveBeenCalledWith(mountPoint)
  })
})

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
import {render} from '@testing-library/react'

import {CourseReport} from '../../types'
import PaceDownloadModal, {PaceDownloadModalProps} from '../pace_download_modal'
import {POLL_DOCX_DELAY} from '../../utils/constants'

const courseReport: CourseReport = {
  id: '1',
  report_type: '',
  course_id: '1',
  progress: 35,
}

const defaultProps: PaceDownloadModalProps = {
  courseReport: courseReport,
  showCourseReport: jest.fn(async () => courseReport),
  setCourseReport: jest.fn(),
}

beforeEach(() => {
  defaultProps.showCourseReport = jest.fn()
  defaultProps.setCourseReport = jest.fn()
})

afterEach(() => {
  jest.clearAllMocks()
})

describe('PaceDownloadModal', () => {
  it('shows nothing when given no course report', () => {
    const modal = render(<PaceDownloadModal {...defaultProps} courseReport={undefined} />)
    expect(modal.queryByTestId('download-course-pace-modal')).not.toBeInTheDocument()
  })

  it('shows progress equal to the course report completion', () => {
    const modal = render(<PaceDownloadModal {...defaultProps} />)
    expect(modal.queryByText('35%')).toBeVisible()
  })

  it('polls the course report', () => {
    jest.useFakeTimers()
    const modal = render(<PaceDownloadModal {...defaultProps} />)
    jest.advanceTimersByTime(POLL_DOCX_DELAY + 100)
    expect(defaultProps.showCourseReport).toHaveBeenCalled()
  })
})

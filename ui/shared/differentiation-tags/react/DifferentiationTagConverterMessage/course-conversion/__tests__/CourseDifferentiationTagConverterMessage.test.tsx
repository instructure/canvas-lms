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

import {render, screen, waitFor} from '@testing-library/react'
import CourseDifferentiationTagConverterMessage from '../CourseDifferentiationTagConverterMessage'

describe('CourseDifferentiationTagConverterMessage', () => {
  const renderComponent = (props = {}) => {
    const defaultProps = {
      courseId: '1',
      activeConversionJob: false,
      ...props,
    }

    return render(<CourseDifferentiationTagConverterMessage {...defaultProps} />)
  }

  it('renders conversion message when no active conversion job', () => {
    renderComponent()
    expect(screen.getByTestId('course-differentiation-tag-converter-warning')).toBeInTheDocument()
  })

  it('renders progress bar when active conversion job', () => {
    renderComponent({activeConversionJob: true})
    expect(screen.getByTestId('course-differentiation-tag-conversion-progress')).toBeInTheDocument()
  })

  it('renders success message when conversion is complete', () => {
    vi.mock('axios', () => ({
      put: vi.fn(() => Promise.resolve({status: 204})),
      get: vi.fn(() =>
        Promise.resolve({status: 200, data: {progress: 100, workflow_state: 'completed'}}),
      ),
    }))

    renderComponent()

    waitFor(() => {
      expect(
        screen.getByTestId('course-differentiation-tag-conversion-success'),
      ).toBeInTheDocument()
    })
  })

  it('renders error message when conversion fails', () => {
    vi.mock('axios', () => ({
      put: vi.fn(() => Promise.reject(new Error('Conversion failed'))),
    }))

    renderComponent()

    waitFor(() => {
      expect(screen.getByTestId('course-differentiation-tag-conversion-error')).toBeInTheDocument()
    })
  })
})

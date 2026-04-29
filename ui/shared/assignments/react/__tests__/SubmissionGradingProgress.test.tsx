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

import SubmissionGradingProgress from '../SubmissionGradingProgress'
import {render, screen} from '@testing-library/react'

const renderComponent = (overrides?: any) => {
  const props = {
    totalSubmissions: 10,
    totalGradedSubmissions: 5,
    ...overrides,
  }

  return render(<SubmissionGradingProgress {...props} />)
}

describe('SubmissionGradingProgress', () => {
  it('renders progress circle', () => {
    renderComponent()
    expect(screen.getByTestId('submission-grading-progress-circle')).toBeInTheDocument()
  })

  it('"No Submissions" state', () => {
    renderComponent({totalSubmissions: 0, totalGradedSubmissions: 0})
    expect(screen.getByText('No Submissions')).toBeInTheDocument()
    expect(screen.getByText('No submitted assignments to grade')).toBeInTheDocument()
  })

  it('"Grading Not Started" state', () => {
    renderComponent({totalSubmissions: 10, totalGradedSubmissions: 0})
    expect(screen.getByText('Grading Not Started')).toBeInTheDocument()
    expect(screen.getByText('0 out of 10 submissions graded')).toBeInTheDocument()
  })

  it('"Grading In Progress" state', () => {
    renderComponent({totalSubmissions: 10, totalGradedSubmissions: 5})
    expect(screen.getByText('Grading In Progress')).toBeInTheDocument()
    expect(screen.getByText('5 out of 10 submissions graded')).toBeInTheDocument()
  })

  it('"Grading Complete" state', () => {
    renderComponent({totalSubmissions: 10, totalGradedSubmissions: 10})
    expect(screen.getByText('Grading Complete')).toBeInTheDocument()
    expect(screen.getByText('10 out of 10 submissions graded')).toBeInTheDocument()
    expect(screen.getByTestId('complete-check-mark')).toBeInTheDocument()
  })
})

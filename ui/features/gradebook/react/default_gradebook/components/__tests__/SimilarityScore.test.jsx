/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import {render, cleanup, screen} from '@testing-library/react'
import SimilarityScore from '../SimilarityScore'

describe('SimilarityScore', () => {
  let defaultProps = {
    hasAdditionalData: false,
    reportUrl: '/my_superlative_report',
    similarityScore: 60,
    status: 'scored',
  }

  afterEach(cleanup)

  const mountComponent = (props = {}) => {
    render(<SimilarityScore {...defaultProps} {...props} />)
  }

  describe('when the originality report has been scored', () => {
    it('displays the similarity score', () => {
      mountComponent()
      expect(screen.getByText('60.0% similarity score')).toBeInTheDocument()
    })

    it('links to the originality report for the submission', () => {
      mountComponent()
      expect(screen.getByRole('link')).toHaveAttribute('href', '/my_superlative_report')
    })

    it('displays an icon corresponding to the passed-in similarity data', () => {
      mountComponent()
      expect(screen.getByTestId('similarity-icon')).toBeInTheDocument()
    })
  })

  describe('when the originality report is in an "error" state', () => {
    it('displays a warning icon', () => {
      mountComponent({status: 'error'})
      expect(screen.getByTestId('similarity-icon')).toBeInTheDocument()
    })

    it('displays an error message', () => {
      mountComponent({status: 'error'})
      expect(screen.getByText(/Error submitting to plagiarism service/)).toBeInTheDocument()
    })
  })

  describe('when the originality data is in a "pending" state', () => {
    it('displays a clock icon', () => {
      mountComponent({status: 'pending'})
      expect(screen.getByTestId('similarity-clock-icon')).toBeInTheDocument()
    })

    it('displays a message indicating the submission is pending', () => {
      mountComponent({status: 'pending'})
      expect(
        screen.getByText(/Submission is being processed by plagiarism service/)
      ).toBeInTheDocument()
    })
  })

  it('displays a message indicating additional reports exist when hasAdditionalData is true', () => {
    mountComponent({hasAdditionalData: true})
    expect(
      screen.getByText(/This submission has plagiarism data for multiple attachments./)
    ).toBeInTheDocument()
  })

  it('does not display a message indicating additional reports exist when hasAdditionalData is false', () => {
    mountComponent()
    expect(
      screen.queryByText('This submission has plagiarism data for multiple attachments.')
    ).not.toBeInTheDocument()
  })
})

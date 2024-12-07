/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import SimilarityIndicator from '../../GradebookGrid/editors/SimilarityIndicator'

describe('SimilarityIndicator', () => {
  const elementRef = () => {}

  const renderSimilarityIndicator = similarityInfo => {
    return render(<SimilarityIndicator elementRef={elementRef} similarityInfo={similarityInfo} />)
  }

  describe('when the status is "scored"', () => {
    it('shows an icon with similarity score', () => {
      const {getByRole} = renderSimilarityIndicator({status: 'scored', similarityScore: 13})
      const button = getByRole('button')
      expect(button).toBeInTheDocument()
      expect(button).toHaveAccessibleDescription('13.0% similarity score')
    })
  })

  describe('when the status is "pending"', () => {
    it('shows a pending status', () => {
      const {getByRole} = renderSimilarityIndicator({status: 'pending'})
      const button = getByRole('button')
      expect(button).toBeInTheDocument()
      expect(button).toHaveAccessibleDescription('Being processed by plagiarism service')
    })
  })

  describe('when the status is "error"', () => {
    it('shows an error status', () => {
      const {getByRole} = renderSimilarityIndicator({status: 'error'})
      const button = getByRole('button')
      expect(button).toBeInTheDocument()
      expect(button).toHaveAccessibleDescription('Error submitting to plagiarism service')
    })
  })
})

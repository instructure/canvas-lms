/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {render, fireEvent} from '@testing-library/react'
import AlignmentOutcomeItem from '../AlignmentOutcomeItem'

describe('AlignmentOutcomeItem', () => {
  const defaultProps = (props = {}) => ({
    title: 'Outcome Title',
    description: 'Outcome Description',
    alignmentCount: 15,
    ...props
  })

  it('renders component', () => {
    const {queryByTestId} = render(<AlignmentOutcomeItem {...defaultProps()} />)
    expect(queryByTestId('alignment-outcome-item')).toBeInTheDocument()
  })

  it('displays outcome title', () => {
    const {getByText} = render(<AlignmentOutcomeItem {...defaultProps()} />)
    expect(getByText('Outcome Title')).toBeInTheDocument()
  })

  it('displays number of alignments', () => {
    const {getByText} = render(<AlignmentOutcomeItem {...defaultProps()} />)
    expect(getByText('Aligned:')).toBeInTheDocument()
    expect(getByText('15')).toBeInTheDocument()
  })

  it('displays right pointing caret when description is collapsed', () => {
    const {queryByTestId} = render(<AlignmentOutcomeItem {...defaultProps()} />)
    expect(queryByTestId('alignment-summary-icon-arrow-right')).toBeInTheDocument()
  })

  it('displays down pointing caret when description is expanded', () => {
    const {queryByTestId, getByText} = render(<AlignmentOutcomeItem {...defaultProps()} />)
    fireEvent.click(getByText('Expand description for outcome Outcome Title'))
    expect(queryByTestId('alignment-summary-icon-arrow-down')).toBeInTheDocument()
  })

  it('expands description when user clicks on right pointing caret', () => {
    const {queryByTestId, getByText} = render(<AlignmentOutcomeItem {...defaultProps()} />)
    fireEvent.click(getByText('Expand description for outcome Outcome Title'))
    expect(queryByTestId('alignment-summary-description-expanded')).toBeInTheDocument()
  })

  it('collapses description when user clicks on downward pointing caret', () => {
    const {queryByTestId, getByText} = render(<AlignmentOutcomeItem {...defaultProps()} />)
    fireEvent.click(getByText('Expand description for outcome Outcome Title'))
    fireEvent.click(getByText('Collapse description for outcome Outcome Title'))
    expect(queryByTestId('alignment-summary-description-truncated')).toBeInTheDocument()
  })

  it('does not show description when user clicks on right pointing caret if no description', () => {
    const {queryByTestId, getByText} = render(
      <AlignmentOutcomeItem {...defaultProps({description: null})} />
    )
    fireEvent.click(getByText('Expand description for outcome Outcome Title'))
    expect(queryByTestId('alignment-summary-description-expanded')).not.toBeInTheDocument()
  })

  it('does not show truncated description if no description', () => {
    const {queryByTestId} = render(<AlignmentOutcomeItem {...defaultProps({description: null})} />)
    expect(queryByTestId('alignment-summary-description-truncated')).not.toBeInTheDocument()
  })
})

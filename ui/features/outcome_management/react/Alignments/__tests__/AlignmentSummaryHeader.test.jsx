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
import {render, within} from '@testing-library/react'
import AlignmentSummaryHeader from '../AlignmentSummaryHeader'

describe('AlignmentSummaryHeader', () => {
  let updateSearchHandlerMock
  let clearSearchHandlerMock
  let updateFilterHandlerMock

  const defaultProps = (props = {}) => ({
    totalOutcomes: 100,
    alignedOutcomes: 50,
    totalAlignments: 200,
    totalArtifacts: 75,
    alignedArtifacts: 60,
    artifactAlignments: 225,
    searchString: 'search value',
    updateSearchHandler: updateSearchHandlerMock,
    clearSearchHandler: clearSearchHandlerMock,
    updateFilterHandler: updateFilterHandlerMock,
    ...props,
  })

  beforeEach(() => {
    updateSearchHandlerMock = jest.fn()
    clearSearchHandlerMock = jest.fn()
    updateFilterHandlerMock = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders component', () => {
    const {getByTestId} = render(<AlignmentSummaryHeader {...defaultProps()} />)
    expect(getByTestId('outcome-alignment-summary-header')).toBeTruthy()
  })

  it('displays alignment statistics', () => {
    const {getByText} = render(<AlignmentSummaryHeader {...defaultProps()} />)
    expect(getByText(/OUTCOMES/)).toBeInTheDocument()
    expect(getByText(/ASSESSABLE ARTIFACTS/)).toBeInTheDocument()
  })

  it('displays filter dropdown', () => {
    const {getByText} = render(<AlignmentSummaryHeader {...defaultProps()} />)
    expect(getByText(/Filter Outcomes/)).toBeInTheDocument()
  })

  it('displays search bar', () => {
    const {getByText} = render(<AlignmentSummaryHeader {...defaultProps()} />)
    expect(getByText(/Search.../)).toBeInTheDocument()
  })

  it('displays total outcomes', () => {
    const {getAllByTestId} = render(
      <AlignmentSummaryHeader {...defaultProps({totalOutcomes: 979})} />
    )
    const {getByText} = within(getAllByTestId('outcome-alignment-stat-item')[0])
    expect(getByText(/979 OUTCOMES/)).toBeInTheDocument()
  })

  it('displays total assessable artifacts', () => {
    const {getAllByTestId} = render(
      <AlignmentSummaryHeader {...defaultProps({totalArtifacts: 878})} />
    )
    const {getByText} = within(getAllByTestId('outcome-alignment-stat-item')[1])
    expect(getByText(/878 ASSESSABLE ARTIFACTS/)).toBeInTheDocument()
  })

  it('calculates properly outcome coverage', () => {
    const {getAllByTestId} = render(
      <AlignmentSummaryHeader {...defaultProps({totalOutcomes: 100, alignedOutcomes: 67})} />
    )
    const {getByText} = within(getAllByTestId('outcome-alignment-stat-item')[0])
    expect(getByText(/67%/)).toBeInTheDocument()
  })

  it('calculates properly outcome coverage if no outcomes', () => {
    const {getAllByTestId} = render(
      <AlignmentSummaryHeader {...defaultProps({totalOutcomes: 0, alignedOutcomes: 80})} />
    )
    const {getByText} = within(getAllByTestId('outcome-alignment-stat-item')[0])
    expect(getByText(/0%/)).toBeInTheDocument()
  })

  it('calculates properly average alignments per outcome', () => {
    const {getAllByTestId} = render(
      <AlignmentSummaryHeader {...defaultProps({totalOutcomes: 100, totalAlignments: 150})} />
    )
    const {getByText} = within(getAllByTestId('outcome-alignment-stat-item')[0])
    expect(getByText(/1.5/)).toBeInTheDocument()
  })

  it('calculates properly average alignments per outcome if no outcomes', () => {
    const {getAllByTestId} = render(
      <AlignmentSummaryHeader {...defaultProps({totalOutcomes: 0, totalAlignments: 150})} />
    )
    const {getByText} = within(getAllByTestId('outcome-alignment-stat-item')[0])
    expect(getByText(/0.0/)).toBeInTheDocument()
  })

  it('calculates properly percent of artifacts with alignments', () => {
    const {getAllByTestId} = render(
      <AlignmentSummaryHeader {...defaultProps({totalArtifacts: 100, alignedArtifacts: 25})} />
    )
    const {getByText} = within(getAllByTestId('outcome-alignment-stat-item')[1])
    expect(getByText(/25%/)).toBeInTheDocument()
  })

  it('calculates properly percent of artifacts with alignments if no artifacts', () => {
    const {getAllByTestId} = render(
      <AlignmentSummaryHeader {...defaultProps({totalArtifacts: 0, alignedArtifacts: 25})} />
    )
    const {getByText} = within(getAllByTestId('outcome-alignment-stat-item')[1])
    expect(getByText(/0%/)).toBeInTheDocument()
  })

  it('calculates properly average alignments per artifact', () => {
    const {getAllByTestId} = render(<AlignmentSummaryHeader {...defaultProps()} />)
    const {getByText} = within(getAllByTestId('outcome-alignment-stat-item')[1])
    expect(getByText(/3.0/)).toBeInTheDocument()
  })

  it('calculates properly average alignments per artifact if no artifacts', () => {
    const {getAllByTestId} = render(
      <AlignmentSummaryHeader {...defaultProps({totalArtifacts: 0, totalAlignments: 150})} />
    )
    const {getByText} = within(getAllByTestId('outcome-alignment-stat-item')[1])
    expect(getByText(/0.0/)).toBeInTheDocument()
  })
})

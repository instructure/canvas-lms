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
import {mount} from 'enzyme'
import {render, fireEvent} from '@testing-library/react'
import AlignmentStatItem from '../AlignmentStatItem'

describe('AlignmentStatItem', () => {
  const defaultProps = (props = {}) => ({
    type: 'outcome',
    count: 10,
    percent: 0.75,
    average: 1.2,
    ...props,
  })

  it('renders component', () => {
    const {getByTestId} = render(<AlignmentStatItem {...defaultProps()} />)
    expect(getByTestId('outcome-alignment-stat-item')).toBeTruthy()
  })

  it('changes stat name depending on type', () => {
    const {getByText, queryByText} = render(
      <AlignmentStatItem {...defaultProps({type: 'artifact'})} />
    )
    expect(queryByText(/OUTCOMES/)).not.toBeInTheDocument()
    expect(getByText(/ASSESSABLE ARTIFACTS/)).toBeInTheDocument()
  })

  it('changes stat description depending on type', () => {
    const {getByText, queryByText} = render(
      <AlignmentStatItem {...defaultProps({type: 'artifact'})} />
    )
    expect(queryByText(/Avg. Alignments per Outcome/)).not.toBeInTheDocument()
    expect(getByText(/Avg. Alignments per Artifact/)).toBeInTheDocument()
  })

  it('displays count stat', () => {
    const {getByText} = render(<AlignmentStatItem {...defaultProps({count: 17})} />)
    expect(getByText(/17 OUTCOMES/)).toBeInTheDocument()
  })

  it('displays percent stat', () => {
    const {getByText} = render(<AlignmentStatItem {...defaultProps({percent: 0.67})} />)
    expect(getByText(/67%/)).toBeInTheDocument()
  })

  it('rounds percent stat', () => {
    const {getByText} = render(<AlignmentStatItem {...defaultProps({percent: 0.678})} />)
    expect(getByText(/68%/)).toBeInTheDocument()
  })

  it('displays average stat', () => {
    const {getByText} = render(<AlignmentStatItem {...defaultProps({average: 3.2})} />)
    expect(getByText(/3.2/)).toBeInTheDocument()
  })

  it('rounds average stat to 1 digit after decimal point', () => {
    const {getByText} = render(<AlignmentStatItem {...defaultProps({average: 3.25})} />)
    expect(getByText(/3.3/)).toBeInTheDocument()
  })

  it('displays info tooltip if type is artifact', () => {
    const {getAllByText, getByTestId} = render(
      <AlignmentStatItem {...defaultProps({type: 'artifact'})} />
    )
    fireEvent.click(getByTestId('outcome-alignment-stat-info-icon'))
    getAllByText(
      /Assessable artifacts include assignments, quizzes, and graded discussions/
    ).forEach(text => expect(text).toBeInTheDocument())
  })

  it('ScreenReaderContent is available when tooltip is displayed', () => {
    const tree = mount(<AlignmentStatItem {...defaultProps({type: 'artifact'})} />)
    const screenReaderNode = tree.find('ScreenReaderContent').first()
    expect(screenReaderNode.text()).toBe(
      'Assessable artifacts include assignments, quizzes, and graded discussions'
    )
  })

  it('does not display info tooltip if type is outcome', () => {
    const {queryByTestId} = render(<AlignmentStatItem {...defaultProps()} />)
    expect(queryByTestId('outcome-alignment-stat-info-icon')).not.toBeInTheDocument()
  })
})

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
    alignments: [
      {
        _id: '1',
        contentType: 'Assignment',
        title: 'Assignment 1',
        url: '/courses/1/outcomes/1/alignments/3',
        moduleTitle: 'Module 1',
        moduleUrl: '/courses/1/modules/1',
        moduleWorkflowState: 'active',
        assignmentContentType: 'assignment',
        assignmentWorkflowState: 'published',
        quizItems: [],
        alignmentsCount: 1,
      },
      {
        _id: '2',
        contentType: 'Assignment',
        title: 'New Quiz',
        url: '/courses/1/assignments/2',
        moduleTitle: 'Module 1',
        moduleUrl: '/courses/1/modules/1',
        moduleWorkflowState: 'active',
        assignmentContentType: 'new_quiz',
        assignmentWorkflowState: 'published',
        quizItems: [],
        alignmentsCount: 2,
      },
    ],
    ...props,
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
    expect(getByText('Alignments:')).toBeInTheDocument()
    expect(getByText('3')).toBeInTheDocument()
  })

  it('does not show truncated description if no description', () => {
    const {queryByTestId} = render(<AlignmentOutcomeItem {...defaultProps({description: null})} />)
    expect(queryByTestId('alignment-summary-description-truncated')).not.toBeInTheDocument()
  })

  describe('when user clicks on right pointing caret', () => {
    it('displays down pointing caret', () => {
      const {queryByTestId, getByText} = render(<AlignmentOutcomeItem {...defaultProps()} />)
      fireEvent.click(getByText('Expand description for outcome Outcome Title'))
      expect(queryByTestId('alignment-summary-icon-arrow-down')).toBeInTheDocument()
    })

    it('expands outcome description', () => {
      const {queryByTestId, getByText} = render(<AlignmentOutcomeItem {...defaultProps()} />)
      fireEvent.click(getByText('Expand description for outcome Outcome Title'))
      expect(queryByTestId('alignment-summary-description-expanded')).toBeInTheDocument()
    })

    it('does not show description if no description', () => {
      const {queryByTestId, getByText} = render(
        <AlignmentOutcomeItem {...defaultProps({description: null})} />
      )
      fireEvent.click(getByText('Expand description for outcome Outcome Title'))
      expect(queryByTestId('alignment-summary-description-expanded')).not.toBeInTheDocument()
    })

    it('displays list of alignments if outcomes has alignments', () => {
      const {getAllByTestId, getByText} = render(<AlignmentOutcomeItem {...defaultProps()} />)
      fireEvent.click(getByText('Expand description for outcome Outcome Title'))
      expect(getAllByTestId('alignment-item').length).toBe(2)
    })

    it('displays no alignments message if outcome has no alignments', () => {
      const {getByText} = render(<AlignmentOutcomeItem {...defaultProps({alignments: []})} />)
      fireEvent.click(getByText('Expand description for outcome Outcome Title'))
      expect(getByText('This outcome has not been aligned')).toBeInTheDocument()
    })
  })

  describe('user clicks on downward pointing caret', () => {
    it('displays right pointing caret', () => {
      const {queryByTestId} = render(<AlignmentOutcomeItem {...defaultProps()} />)
      expect(queryByTestId('alignment-summary-icon-arrow-right')).toBeInTheDocument()
    })

    it('collapses outcome description', () => {
      const {queryByTestId, getByText} = render(<AlignmentOutcomeItem {...defaultProps()} />)
      fireEvent.click(getByText('Expand description for outcome Outcome Title'))
      fireEvent.click(getByText('Collapse description for outcome Outcome Title'))
      expect(queryByTestId('alignment-summary-description-truncated')).toBeInTheDocument()
    })

    it('does not show description if no description', () => {
      const {queryByTestId, getByText} = render(
        <AlignmentOutcomeItem {...defaultProps({description: null})} />
      )
      fireEvent.click(getByText('Expand description for outcome Outcome Title'))
      fireEvent.click(getByText('Collapse description for outcome Outcome Title'))
      expect(queryByTestId('alignment-summary-description-truncated')).not.toBeInTheDocument()
    })

    it('hides list of alignments if outcomes has alignments', () => {
      const {queryByTestId, getByText} = render(<AlignmentOutcomeItem {...defaultProps()} />)
      fireEvent.click(getByText('Expand description for outcome Outcome Title'))
      fireEvent.click(getByText('Collapse description for outcome Outcome Title'))
      expect(queryByTestId('alignment-item')).not.toBeInTheDocument()
    })

    it('hides no alignments message if outcome has no alignments', () => {
      const {queryByText, getByText} = render(
        <AlignmentOutcomeItem {...defaultProps({alignments: []})} />
      )
      fireEvent.click(getByText('Expand description for outcome Outcome Title'))
      fireEvent.click(getByText('Collapse description for outcome Outcome Title'))
      expect(queryByText('This outcome has not been aligned')).not.toBeInTheDocument()
    })
  })
})

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
import {render} from '@testing-library/react'
import AlignmentItem from '../AlignmentItem'

describe('AlignmentItem', () => {
  const defaultProps = (props = {}) => ({
    id: '1',
    contentType: 'Assignment',
    title: 'Assignment 1',
    url: '/courses/1/outcomes/1/alignments/3',
    moduleTitle: 'Module 1',
    moduleUrl: '/courses/1/modules/1',
    moduleWorkflowState: 'active',
    assignmentContentType: 'Assignment',
    assignmentWorkflowState: 'published',
    quizItems: [],
    ...props,
  })

  it('renders component', () => {
    const {queryByTestId} = render(<AlignmentItem {...defaultProps()} />)
    expect(queryByTestId('alignment-item')).toBeInTheDocument()
  })

  it('displays alignment title', () => {
    const {getByText} = render(<AlignmentItem {...defaultProps()} />)
    expect(getByText('Assignment 1')).toBeInTheDocument()
  })

  it('displays alignment title appended with (unpublished) if alignment is unpublished', () => {
    const {getByText} = render(
      <AlignmentItem {...defaultProps({assignmentWorkflowState: 'unpublished'})} />
    )
    expect(getByText('Assignment 1 (unpublished)')).toBeInTheDocument()
  })

  it('displays module title', () => {
    const {getByText} = render(<AlignmentItem {...defaultProps()} />)
    expect(getByText('Module 1')).toBeInTheDocument()
  })

  it('displays module title appended with (unpublished) if module is unpublished', () => {
    const {getByText} = render(
      <AlignmentItem {...defaultProps({moduleWorkflowState: 'unpublished'})} />
    )
    expect(getByText('Module 1 (unpublished)')).toBeInTheDocument()
  })

  it('displays module title None if module title missing', () => {
    const {getByText} = render(<AlignmentItem {...defaultProps({moduleTitle: null})} />)
    expect(getByText('None')).toBeInTheDocument()
  })

  it('displays module title None if module url missing', () => {
    const {getByText} = render(<AlignmentItem {...defaultProps({moduleUrl: null})} />)
    expect(getByText('None')).toBeInTheDocument()
  })

  it('displays assignment icon if assignment content type is assignment', () => {
    const {getByTestId} = render(<AlignmentItem {...defaultProps()} />)
    expect(getByTestId('alignment-item-assignment-icon')).toBeInTheDocument()
  })

  it('displays classic quiz icon if assignment content type is quiz', () => {
    const {getByTestId} = render(
      <AlignmentItem {...defaultProps({assignmentContentType: 'quiz'})} />
    )
    expect(getByTestId('alignment-item-quiz-icon')).toBeInTheDocument()
  })

  it('displays discussion icon if assignment content type is discussion', () => {
    const {getByTestId} = render(
      <AlignmentItem {...defaultProps({assignmentContentType: 'discussion'})} />
    )
    expect(getByTestId('alignment-item-discussion-icon')).toBeInTheDocument()
  })

  it('displays rubric icon if alignment type is rubric', () => {
    const {getByTestId} = render(<AlignmentItem {...defaultProps({contentType: 'Rubric'})} />)
    expect(getByTestId('alignment-item-rubric-icon')).toBeInTheDocument()
  })

  it('displays bank icon if alignment type is question bank', () => {
    const {getByTestId} = render(
      <AlignmentItem {...defaultProps({contentType: 'AssessmentQuestionBank'})} />
    )
    expect(getByTestId('alignment-item-bank-icon')).toBeInTheDocument()
  })

  it('displays assignment icon by default if assignment content type not matched', () => {
    const {getByTestId} = render(<AlignmentItem {...defaultProps({assignmentContentType: null})} />)
    expect(getByTestId('alignment-item-assignment-icon')).toBeInTheDocument()
  })

  it('links alignment title correctly', () => {
    const {getByRole} = render(<AlignmentItem {...defaultProps()} />)
    const titleLink = getByRole('link', {name: 'Assignment 1'})
    expect(titleLink).toBeTruthy()
    expect(titleLink).toHaveAttribute('href', '/courses/1/outcomes/1/alignments/3')
  })

  it('links module title correctly', () => {
    const {getByRole} = render(<AlignmentItem {...defaultProps()} />)
    const titleLink = getByRole('link', {name: 'Module 1'})
    expect(titleLink).toBeTruthy()
    expect(titleLink).toHaveAttribute('href', '/courses/1/modules/1')
  })

  it('does not display list of quiz items if alignment is not to new quiz', () => {
    const {queryByText} = render(
      <AlignmentItem
        {...defaultProps({
          assignmentContentType: 'quiz',
          quizItems: [{_id: 1, title: 'Question 1'}],
        })}
      />
    )
    expect(queryByText('Question 1')).not.toBeInTheDocument()
  })

  describe('alignment to new quiz', () => {
    it('displays new quiz icon', () => {
      const {getByTestId} = render(
        <AlignmentItem {...defaultProps({assignmentContentType: 'new_quiz'})} />
      )
      expect(getByTestId('alignment-item-new-quiz-icon')).toBeInTheDocument()
    })

    it('displays list of quiz items', () => {
      const {getByText} = render(
        <AlignmentItem
          {...defaultProps({
            assignmentContentType: 'new_quiz',
            quizItems: [{_id: 1, title: 'Question 1'}],
          })}
        />
      )
      expect(getByText('Aligned Questions')).toBeInTheDocument()
      expect(getByText('Question 1')).toBeInTheDocument()
    })

    it('does not display list of quiz items if there are no items', () => {
      const {queryByText} = render(
        <AlignmentItem
          {...defaultProps({
            assignmentContentType: 'new_quiz',
          })}
        />
      )
      expect(queryByText('Aligned Questions')).not.toBeInTheDocument()
    })
  })
})

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
import {render, fireEvent} from '@testing-library/react'
import CheckpointsGradeInputs, {REPLY_TO_ENTRY, REPLY_TO_TOPIC} from '../CheckpointsGradeInputs'

describe('CheckpointsGradeInputs', () => {
  let onReplyToTopicSubmissionChangeMock: () => void
  let onReplyToEntrySubmissionChangeMock: () => void

  const defaultProps = (overrides?: any) => ({
    assignment: {
      grading_type: 'points',
      total_score: '15',
      checkpoints: [
        {
          tag: REPLY_TO_TOPIC,
          submission_id: '2',
          points_possible: 10,
          entered_score: 10,
        },
        {
          tag: REPLY_TO_ENTRY,
          submission_id: '3',
          points_possible: 5,
          entered_score: 5,
        },
      ],
    },
    canEdit: true,
    onReplyToTopicSubmissionChange: onReplyToTopicSubmissionChangeMock,
    onReplyToEntrySubmissionChange: onReplyToEntrySubmissionChangeMock,
    ...overrides,
  })

  beforeEach(() => {
    onReplyToTopicSubmissionChangeMock = jest.fn()
    onReplyToEntrySubmissionChangeMock = jest.fn()
  })

  it('should render', () => {
    const {getByTestId, getAllByTestId} = render(<CheckpointsGradeInputs {...defaultProps()} />)
    expect(getByTestId('reply-to-topic-input')).toBeInTheDocument()
    expect(getByTestId('reply-to-entry-input')).toBeInTheDocument()

    // Check values of inputs
    const inputs = getAllByTestId('default-grade-input')
    expect(inputs).toHaveLength(2)
    expect(inputs[0]).toHaveValue('10') // reply_to_topic
    expect(inputs[1]).toHaveValue('5') // reply_to_entry
  })

  it('should disable inputs when canEdit is false', () => {
    const {getAllByTestId} = render(<CheckpointsGradeInputs {...defaultProps({canEdit: false})} />)
    const inputs = getAllByTestId('default-grade-input')
    inputs.forEach(input => {
      expect(input).toBeDisabled()
    })
  })

  it('should call submission change callbacks when scores are changed', () => {
    const {getAllByTestId} = render(<CheckpointsGradeInputs {...defaultProps()} />)
    const inputs = getAllByTestId('default-grade-input')

    // Change values of reply_to_topic and reply_to_entry inputs
    inputs.forEach(input => {
      input.focus()
      fireEvent.change(input, {target: {value: '4'}})
      input.blur()
    })

    expect(onReplyToTopicSubmissionChangeMock).toHaveBeenCalledWith(4)
    expect(onReplyToEntrySubmissionChangeMock).toHaveBeenCalledWith(4)
  })

  describe('when gradingType is pass_fail', () => {
    it('shows "Complete" options if it is default value', () => {
      const props = defaultProps()
      props.assignment.grading_type = 'pass_fail'
      props.assignment.checkpoints[0].entered_score = 10
      props.assignment.checkpoints[1].entered_score = 5
      const {getAllByTestId} = render(<CheckpointsGradeInputs {...props} />)
      const inputs = getAllByTestId('select-dropdown')

      // Check values of inputs
      expect(inputs[0]).toHaveValue('Complete') // reply_to_topic
      expect(inputs[1]).toHaveValue('Complete') // reply_to_entry
    })

    it('shows "Incomplete" options if it is default value', () => {
      const props = defaultProps()
      props.assignment.grading_type = 'pass_fail'
      props.assignment.checkpoints[0].entered_score = 0
      props.assignment.checkpoints[1].entered_score = 0

      const {getAllByTestId} = render(<CheckpointsGradeInputs {...props} />)
      const inputs = getAllByTestId('select-dropdown')

      // Check values of inputs
      expect(inputs[0]).toHaveValue('Incomplete') // reply_to_topic
      expect(inputs[1]).toHaveValue('Incomplete') // reply_to_entry
    })
  })
})

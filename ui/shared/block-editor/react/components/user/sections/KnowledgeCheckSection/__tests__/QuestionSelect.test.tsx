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
import {render, screen, fireEvent, waitFor} from '@testing-library/react'
import '@testing-library/jest-dom/extend-expect'
import QuestionSelect from '../QuestionSelect'

import {type QuestionProps} from '../types'

const testUnsupportedQuestion: QuestionProps = {
  id: '1',
  entry_editable: false,
  entry_type: 'question',
  points_possible: 1,
  position: 1,
  properties: {},
  status: 'published',
  stimulus_quiz_entry_id: '1',
  entry: {
    id: '1',
    title: 'Unsupported Question',
    answer_feedback: {},
    calculator_type: 'basic',
    feedback: {
      neutral: '',
      correct: '',
      incorrect: '',
    },
    interaction_data: {
      true_choice: 'True',
      false_choice: 'False',
    },
    interaction_type_slug: 'true_false',
    item_body: null,
    properties: {},
    scoring_algorithm: 'none',
    scoring_data: {
      value: true,
    },
  },
}

const testSupportedQuestion: QuestionProps = {
  id: '2',
  entry_editable: false,
  entry_type: 'question',
  points_possible: 1,
  position: 2,
  properties: {},
  status: 'published',
  stimulus_quiz_entry_id: '2',
  entry: {
    id: '2',
    title: 'True or false?',
    answer_feedback: {},
    calculator_type: 'basic',
    feedback: {
      neutral: '',
      correct: '',
      incorrect: '',
    },
    interaction_data: {
      true_choice: 'True',
      false_choice: 'False',
    },
    interaction_type_slug: 'true_false',
    item_body: 'The sky is blue',
    properties: {},
    scoring_algorithm: 'none',
    scoring_data: {
      value: true,
    },
  },
}

const testMissingValuesQuestion: QuestionProps = {
  id: '3',
  entry_editable: false,
  entry_type: 'question',
  points_possible: 1,
  position: 3,
  properties: {},
  status: 'published',
  stimulus_quiz_entry_id: '3',
  entry: {
    id: '3',
    title: null,
    answer_feedback: {},
    calculator_type: 'basic',
    feedback: {
      neutral: '',
      correct: '',
      incorrect: '',
    },
    interaction_data: {
      true_choice: 'True',
      false_choice: 'False',
    },
    interaction_type_slug: 'true_false',
    item_body: null,
    properties: {},
    scoring_algorithm: 'none',
    scoring_data: {
      value: true,
    },
  },
}

const testQuestions: QuestionProps[] = [
  testUnsupportedQuestion,
  testSupportedQuestion,
  testMissingValuesQuestion,
]

describe('QuestionSelect', () => {
  const mockOnSelect = jest.fn()

  it('renders loading spinner when loading', () => {
    render(<QuestionSelect onSelect={mockOnSelect} questions={null} />)
    expect(screen.getByText('Loading...')).toBeInTheDocument()
  })

  it('renders no questions found if questions array is empty', () => {
    render(<QuestionSelect onSelect={mockOnSelect} questions={[]} />)
    expect(screen.getByText('No questions found.')).toBeInTheDocument()
  })

  it('calls onSelect when a QuestionToggle is clicked', async () => {
    render(<QuestionSelect onSelect={mockOnSelect} questions={testQuestions} />)
    const toggle = screen.getByText(testQuestions[0].entry.title ?? '')
    fireEvent.click(toggle)
    await waitFor(() => expect(mockOnSelect).toHaveBeenCalled())
  })

  it('renders the correct question titles', () => {
    render(<QuestionSelect onSelect={mockOnSelect} questions={testQuestions} />)
    expect(screen.getByText(testUnsupportedQuestion.entry.title ?? '')).toBeInTheDocument()
    expect(screen.getByText(testSupportedQuestion.entry.title ?? '')).toBeInTheDocument()
    expect(screen.getByText(`Question ${testMissingValuesQuestion.position}`)).toBeInTheDocument()
  })

  it('filters questions based on title', () => {
    render(<QuestionSelect onSelect={mockOnSelect} questions={testQuestions} />)
    const input = screen.getByPlaceholderText('Search questions...')
    fireEvent.change(input, {target: {value: 'true or false?'}})
    expect(screen.queryByText(testUnsupportedQuestion.entry.title ?? '')).not.toBeInTheDocument()
    expect(screen.getByText(testSupportedQuestion.entry.title ?? '')).toBeInTheDocument()
  })

  it('filters questions based on body', () => {
    render(<QuestionSelect onSelect={mockOnSelect} questions={testQuestions} />)
    const input = screen.getByPlaceholderText('Search questions...')
    fireEvent.change(input, {target: {value: 'blue'}})
    expect(screen.queryByText(testUnsupportedQuestion.entry.title ?? '')).not.toBeInTheDocument()
    expect(screen.getByText(testSupportedQuestion.entry.title ?? '')).toBeInTheDocument()
  })
})

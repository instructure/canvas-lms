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
import {testQuestions} from './testQuestions'

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
    // @ts-expect-error
    render(<QuestionSelect onSelect={mockOnSelect} questions={testQuestions} />)
    const toggle = screen.getByText(testQuestions[0].entry.title)
    fireEvent.click(toggle)
    await waitFor(() => expect(mockOnSelect).toHaveBeenCalled())
  })

  it('renders the correct question titles', () => {
    // @ts-expect-error
    render(<QuestionSelect onSelect={mockOnSelect} questions={testQuestions} />)
    testQuestions.forEach(question => {
      expect(screen.getByText(question.entry.title)).toBeInTheDocument()
    })
  })

  it('filters questions based on search input', () => {
    // @ts-expect-error
    render(<QuestionSelect onSelect={mockOnSelect} questions={testQuestions} />)
    const input = screen.getByPlaceholderText('Search questions...')
    fireEvent.change(input, {target: {value: 'test'}})
    const filteredQuestions = testQuestions.filter(question =>
      question.entry.title.toLowerCase().includes('blue')
    )
    filteredQuestions.forEach(question => {
      expect(screen.getByText(question.entry.title)).toBeInTheDocument()
    })
  })
})

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
import {render, fireEvent} from '@testing-library/react'
import QuestionToggle from '../QuestionToggle'
import {testSupportedQuestion, testUnsupportedQuestion} from './testQuestions'

describe('QuestionToggle', () => {
  const mockOnSelect = jest.fn()

  const renderComponent = (question = testSupportedQuestion) => {
    return render(<QuestionToggle question={question} onSelect={mockOnSelect} />)
  }

  it('renders the question summary correctly', () => {
    const {getByText} = renderComponent()
    expect(getByText('2')).toBeInTheDocument()
    expect(getByText('True/False')).toBeInTheDocument()
    expect(getByText('Is this true or false?')).toBeInTheDocument()
  })

  it('calls onSelect with the question when toggled', () => {
    const {getByText} = renderComponent()
    fireEvent.click(getByText('Is this true or false?'))
    expect(mockOnSelect).toHaveBeenCalledWith(testSupportedQuestion)
  })

  it('toggles the expanded state when clicked', () => {
    const {getByText, getByTestId} = renderComponent()
    const summary = getByText('Is this true or false?')
    fireEvent.click(summary)
    const toggleButton = getByTestId(`question-toggle-${testSupportedQuestion.id}`)
    expect(toggleButton).toHaveAttribute('aria-expanded', 'true')
    fireEvent.click(summary)
    expect(toggleButton).toHaveAttribute('aria-expanded', 'false')
  })

  it('renders the question details when expanded', () => {
    const {getByText, getByTestId} = renderComponent()
    fireEvent.click(getByText('Is this true or false?'))
    expect(getByTestId(`question-toggle-${testSupportedQuestion.id}`)).toHaveAttribute(
      'aria-expanded',
      'true',
    )
    expect(getByText('Is this true or false?')).toBeInTheDocument()
  })

  it('disables interaction for unsupported question types', () => {
    // @ts-expect-error
    const {getByText} = renderComponent(testUnsupportedQuestion)
    fireEvent.click(getByText('Why should we categorize things?'))
    expect(mockOnSelect).toHaveBeenCalledWith(null)
  })
})

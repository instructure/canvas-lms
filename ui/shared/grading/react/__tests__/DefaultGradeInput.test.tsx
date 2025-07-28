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
import DefaultGradeInput from '../DefaultGradeInput'

describe('DefaultGradeInput', () => {
  let onGradeInputChangeMock = jest.fn()

  const defaultProps = (overrides?: any) => ({
    disabled: false,
    gradingType: 'points',
    onGradeInputChange: onGradeInputChangeMock,
    header: 'Reply to Topic',
    outOfTextValue: '10',
    name: 'reply_to_topic',
    defaultValue: '8',
    ...overrides,
  })

  beforeEach(() => {
    onGradeInputChangeMock = jest.fn()
  })

  it('should render', () => {
    const {getByTestId, getByText} = render(<DefaultGradeInput {...defaultProps()} />)
    expect(getByTestId('default-grade-input-text')).toBeInTheDocument()
    expect(getByText('Reply to Topic')).toBeInTheDocument()
    expect(getByTestId('default-grade-input')).toHaveValue('8')
    expect(getByTestId('default-grade-input')).not.toBeDisabled()
  })

  it('should disable input when disabled is true', () => {
    const props = defaultProps({disabled: true})
    const {getByTestId} = render(<DefaultGradeInput {...props} />)
    expect(getByTestId('default-grade-input')).toBeDisabled()
  })

  it('should call onGradeInputChange when input changes', () => {
    const {getByTestId} = render(<DefaultGradeInput {...defaultProps()} />)
    fireEvent.change(getByTestId('default-grade-input'), {target: {value: '9'}})
    // It fires the event when input is blurred
    fireEvent.blur(getByTestId('default-grade-input'))
    expect(onGradeInputChangeMock).toHaveBeenCalledWith('9', false)
  })

  it('should render error message if text input is empty', () => {
    const {getByTestId, getByText} = render(<DefaultGradeInput {...defaultProps()} />)
    fireEvent.change(getByTestId('default-grade-input'), {target: {value: ''}})
    fireEvent.blur(getByTestId('default-grade-input'))
    expect(getByText('Enter a grade')).toBeInTheDocument()
  })

  describe('when gradingType is pass_fail', () => {
    it('should render a select input', () => {
      const props = defaultProps({gradingType: 'pass_fail'})
      const {getByTestId} = render(<DefaultGradeInput {...props} />)
      expect(getByTestId('default-grade-input-select')).toBeInTheDocument()
    })

    it('should render "Complete" option if it is default value', () => {
      const props = defaultProps({gradingType: 'pass_fail', defaultValue: 'complete'})
      const {getByTestId} = render(<DefaultGradeInput {...props} />)
      expect(getByTestId('select-dropdown')).toHaveValue('Complete')
    })

    it('should render "Incomplete" option if it is default value', () => {
      const props = defaultProps({gradingType: 'pass_fail', defaultValue: 'incomplete'})
      const {getByTestId} = render(<DefaultGradeInput {...props} />)
      expect(getByTestId('select-dropdown')).toHaveValue('Incomplete')
    })

    it('should disable select when disabled is true', () => {
      const props = defaultProps({gradingType: 'pass_fail', disabled: true})
      const {getByTestId} = render(<DefaultGradeInput {...props} />)
      expect(getByTestId('select-dropdown')).toBeDisabled()
    })

    it('should call onGradeInputChange when select changes', () => {
      const props = defaultProps({gradingType: 'pass_fail'})
      const {getByTestId} = render(<DefaultGradeInput {...props} />)
      fireEvent.click(getByTestId('select-dropdown'))
      fireEvent.click(getByTestId('complete-dropdown-option'))
      expect(onGradeInputChangeMock).toHaveBeenCalledWith('complete', true)
    })
  })
})

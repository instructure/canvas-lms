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
import {render, fireEvent, screen} from '@testing-library/react'
import {SpeedGraderNavigator} from '../SpeedGraderNavigator'
import useSpeedGrader from '../../../hooks/useSpeedGrader'

jest.mock('../../../hooks/useSpeedGrader')

describe('SpeedGraderNavigator', () => {
  beforeEach(() => {
    useSpeedGrader.mockImplementation(() => ({
      isInSpeedGrader: true,
      handlePreviousStudentReply: jest.fn(),
      handleNextStudentReply: jest.fn(),
      handleJumpFocusToSpeedGrader: jest.fn(),
    }))
  })

  const setup = () => {
    return render(<SpeedGraderNavigator />)
  }

  it('renders all buttons when all handlers are provided', () => {
    setup()
    expect(screen.getByTestId('previous-in-speedgrader')).toBeInTheDocument()
    expect(screen.getByTestId('next-in-speedgrader')).toBeInTheDocument()
    expect(screen.getByTestId('jump-to-speedgrader-navigation')).toBeInTheDocument()
  })

  it('does not render Previous button when handlePreviousStudentReply is null', () => {
    useSpeedGrader.mockImplementation(() => ({
      isInSpeedGrader: true,
      handlePreviousStudentReply: null,
      handleNextStudentReply: jest.fn(),
      handleJumpFocusToSpeedGrader: jest.fn(),
    }))
    setup()
    expect(screen.queryByTestId('previous-in-speedgrader')).not.toBeInTheDocument()
    expect(screen.getByTestId('next-in-speedgrader')).toBeInTheDocument()
    expect(screen.getByTestId('jump-to-speedgrader-navigation')).toBeInTheDocument()
  })

  it('does not render Next button when handleNextStudentReply is null', () => {
    useSpeedGrader.mockImplementation(() => ({
      isInSpeedGrader: true,
      handlePreviousStudentReply: jest.fn(),
      handleNextStudentReply: null,
      handleJumpFocusToSpeedGrader: jest.fn(),
    }))
    setup()
    expect(screen.getByTestId('previous-in-speedgrader')).toBeInTheDocument()
    expect(screen.queryByTestId('next-in-speedgrader')).not.toBeInTheDocument()
    expect(screen.getByTestId('jump-to-speedgrader-navigation')).toBeInTheDocument()
  })

  it('calls handlePreviousStudentReply when Previous button is clicked', () => {
    const mockHandlePrevious = jest.fn()
    useSpeedGrader.mockImplementation(() => ({
      isInSpeedGrader: true,
      handlePreviousStudentReply: mockHandlePrevious,
      handleNextStudentReply: jest.fn(),
      handleJumpFocusToSpeedGrader: jest.fn(),
    }))
    setup()
    fireEvent.click(screen.getByTestId('previous-in-speedgrader'))
    expect(mockHandlePrevious).toHaveBeenCalledTimes(1)
  })

  it('calls handleNextStudentReply when Next button is clicked', () => {
    const mockHandleNext = jest.fn()
    useSpeedGrader.mockImplementation(() => ({
      isInSpeedGrader: true,
      handlePreviousStudentReply: jest.fn(),
      handleNextStudentReply: mockHandleNext,
      handleJumpFocusToSpeedGrader: jest.fn(),
    }))
    setup()
    fireEvent.click(screen.getByTestId('next-in-speedgrader'))
    expect(mockHandleNext).toHaveBeenCalledTimes(1)
  })

  it('calls handleJumpFocusToSpeedGrader when Jump button is clicked', () => {
    const mockHandleJump = jest.fn()
    useSpeedGrader.mockImplementation(() => ({
      isInSpeedGrader: true,
      handlePreviousStudentReply: jest.fn(),
      handleNextStudentReply: jest.fn(),
      handleJumpFocusToSpeedGrader: mockHandleJump,
    }))
    setup()
    fireEvent.click(screen.getByTestId('jump-to-speedgrader-navigation'))
    expect(mockHandleJump).toHaveBeenCalledTimes(1)
  })

  it('becomes visible on focus', () => {
    const {container} = setup()
    expect(container.firstChild).toHaveAttribute('aria-hidden', 'true')
    fireEvent.focus(container.firstChild)
    expect(container.firstChild).toHaveAttribute('aria-hidden', 'false')
  })

  it('becomes hidden on blur', () => {
    const {container} = setup()
    fireEvent.focus(container.firstChild)
    fireEvent.blur(container.firstChild)
    expect(container.firstChild).toHaveStyle('clip: rect(0 0 0 0)')
  })
})

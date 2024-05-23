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
import {render, fireEvent, screen, within} from '@testing-library/react'

import AcceptGradesButton from '../AcceptGradesButton'
import {FAILURE, STARTED, SUCCESS} from '../../../grades/GradeActions'

describe('GradeSummary AcceptGradesButton', () => {
  let props

  beforeEach(() => {
    props = {
      id: 'required_because_idk',
      acceptGradesStatus: null,
      graderName: 'Jackie Chan',
      onClick: jest.fn(),
      selectionDetails: {
        allowed: true,
        provisionalGradeIds: ['4601'],
      },
    }
  })

  describe('when grades have not been accepted', () => {
    beforeEach(() => {
      render(<AcceptGradesButton {...props} />)
    })

    test('is labeled with "Accept grades by" and "Accept"', () => {
      const btn = screen.getByRole('button')
      const sr_label = within(btn).getByText('Accept grades by Jackie Chan')
      const visible_label = within(btn).getByText('Accept')
      expect(sr_label.className.includes('screenReaderContent')).toBe(true)
      expect(visible_label).toHaveAttribute('aria-hidden', 'true')
    })

    test('is not disabled', () => {
      expect(screen.getByRole('button')).not.toBeDisabled()
    })

    test('calls the onClick prop when clicked', () => {
      fireEvent.click(screen.getByRole('button'))
      expect(props.onClick).toHaveBeenCalledTimes(1)
    })
  })

  describe('when grades are being accepted', () => {
    beforeEach(() => {
      props.acceptGradesStatus = STARTED
      render(<AcceptGradesButton {...props} />)
    })

    test('is labeled with "Accepting"', () => {
      expect(screen.getByRole('button', {name: 'Accepting'})).toBeInTheDocument()
    })

    test('is not disabled', () => {
      expect(screen.getByRole('button')).not.toBeDisabled()
    })

    test('does not call the onClick prop when clicked', () => {
      fireEvent.click(screen.getByRole('button'))
      expect(props.onClick).not.toHaveBeenCalled()
    })
  })

  describe('when grades have been accepted', () => {
    beforeEach(() => {
      props.acceptGradesStatus = SUCCESS
      props.selectionDetails.provisionalGradeIds = []
      render(<AcceptGradesButton {...props} />)
    })

    test('is labeled with "Accepted"', () => {
      expect(screen.getByRole('button', {name: 'Accepted'})).toBeInTheDocument()
    })

    test('is not disabled', () => {
      expect(screen.getByRole('button')).not.toBeDisabled()
    })

    test('does not call the onClick prop when clicked', () => {
      fireEvent.click(screen.getByRole('button'))
      expect(props.onClick).not.toHaveBeenCalled()
    })
  })

  describe('when grades were previously accepted', () => {
    beforeEach(() => {
      props.acceptGradesStatus = null
      props.selectionDetails.provisionalGradeIds = []
      render(<AcceptGradesButton {...props} />)
    })

    test('is labeled with "Accepted"', () => {
      expect(screen.getByRole('button', {name: 'Accepted'})).toBeInTheDocument()
    })

    test('is disabled', () => {
      expect(screen.getByRole('button')).toBeDisabled()
    })

    test('does not call the onClick prop when clicked', () => {
      fireEvent.click(screen.getByRole('button'))
      expect(props.onClick).not.toHaveBeenCalled()
    })
  })

  describe('when grades failed to be accepted', () => {
    beforeEach(() => {
      props.acceptGradesStatus = FAILURE
      render(<AcceptGradesButton {...props} />)
    })

    test('is labeled with "Accept grades by" and "Accept"', () => {
      const btn = screen.getByRole('button')
      const sr_label = within(btn).getByText('Accept grades by Jackie Chan')
      const visible_label = within(btn).getByText('Accept')
      expect(sr_label.className.includes('screenReaderContent')).toBe(true)
      expect(visible_label).toHaveAttribute('aria-hidden', 'true')
    })

    test('is not disabled', () => {
      expect(screen.getByRole('button')).not.toBeDisabled()
    })

    test('calls the onClick prop when clicked', () => {
      fireEvent.click(screen.getByRole('button'))
      expect(props.onClick).toHaveBeenCalledTimes(1)
    })
  })

  describe('when grades cannot be bulk selected for the grader', () => {
    beforeEach(() => {
      props.selectionDetails = {
        allowed: false,
        provisionalGradeIds: [],
      }
      render(<AcceptGradesButton {...props} />)
    })

    test('is labeled with "Accept grades by" and "Accept"', () => {
      const btn = screen.getByRole('button')
      const sr_label = within(btn).getByText('Accept grades by Jackie Chan')
      const visible_label = within(btn).getByText('Accept')
      expect(sr_label.className.includes('screenReaderContent')).toBe(true)
      expect(visible_label).toHaveAttribute('aria-hidden', 'true')
    })

    test('is disabled', () => {
      expect(screen.getByRole('button')).toBeDisabled()
    })

    test('does not call the onClick prop when clicked', () => {
      fireEvent.click(screen.getByRole('button'))
      expect(props.onClick).not.toHaveBeenCalled()
    })
  })
})

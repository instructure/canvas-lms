/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {render, screen, fireEvent} from '@testing-library/react'

import {
  FAILURE,
  NOT_ALL_SUBMISSIONS_HAVE_SELECTED_GRADE,
  SELECTED_GRADES_FROM_UNAVAILABLE_GRADERS,
  STARTED,
} from '../../assignment/AssignmentActions'
import ReleaseButton from '../ReleaseButton'

describe('GradeSummary ReleaseButton', () => {
  const props = {
    gradesReleased: false,
    onClick: jest.fn(),
    releaseGradesStatus: null,
  }

  beforeEach(() => {
    props.gradesReleased = false
    props.onClick.mockClear()
    props.releaseGradesStatus = null
  })

  describe('when grades have not been released', () => {
    test('is labeled with "Release Grades"', () => {
      render(<ReleaseButton {...props} />)
      expect(screen.getByText('Release Grades')).toBeInTheDocument()
    })

    test('calls the onClick prop when clicked', () => {
      render(<ReleaseButton {...props} />)
      fireEvent.click(screen.getByRole('button'))
      expect(props.onClick).toHaveBeenCalledTimes(1)
    })
  })

  describe('when grades are being released', () => {
    beforeEach(() => {
      props.releaseGradesStatus = STARTED
    })

    test('is labeled with "Releasing Grades"', () => {
      render(<ReleaseButton {...props} />)
      expect(screen.getByRole('button', {name: 'Releasing Grades'})).toBeInTheDocument()
    })

    test('does not call the onClick prop when clicked', () => {
      render(<ReleaseButton {...props} />)
      fireEvent.click(screen.getByRole('button'))
      expect(props.onClick).not.toHaveBeenCalled()
    })
  })

  describe('when grades have been released', () => {
    beforeEach(() => {
      props.gradesReleased = true
    })

    test('does not call the onClick prop when clicked', () => {
      render(<ReleaseButton {...props} />)
      fireEvent.click(screen.getByRole('button'))
      expect(props.onClick).not.toHaveBeenCalled()
    })

    test('is labeled with "Grades Released"', () => {
      render(<ReleaseButton {...props} />)
      expect(screen.getByRole('button', {name: 'Grades Released'})).toBeInTheDocument()
    })
  })

  describe('when grade releasing failed', () => {
    beforeEach(() => {
      props.releaseGradesStatus = FAILURE
    })

    test('is labeled with "Release Grades"', () => {
      render(<ReleaseButton {...props} />)
      expect(screen.getByRole('button', {name: 'Release Grades'})).toBeInTheDocument()
    })

    test('calls the onClick prop when clicked', () => {
      render(<ReleaseButton {...props} />)
      fireEvent.click(screen.getByRole('button'))
      expect(props.onClick).toHaveBeenCalledTimes(1)
    })
  })

  describe('when grade releasing failed for missing grade selections', () => {
    beforeEach(() => {
      props.releaseGradesStatus = NOT_ALL_SUBMISSIONS_HAVE_SELECTED_GRADE
    })

    test('is labeled with "Release Grades"', () => {
      render(<ReleaseButton {...props} />)
      expect(screen.getByText('Release Grades')).toBeInTheDocument()
    })

    test('calls the onClick prop when clicked', () => {
      render(<ReleaseButton {...props} />)
      fireEvent.click(screen.getByRole('button'))
      expect(props.onClick).toHaveBeenCalledTimes(1)
    })
  })

  describe('when there are graders with inactive enrollment', () => {
    test('enables onClick when releaseGradesStatus is null', () => {
      props.releaseGradesStatus = null
      render(<ReleaseButton {...props} />)
      fireEvent.click(screen.getByRole('button'))
      expect(props.onClick).toHaveBeenCalledTimes(1)
    })

    test('disables onClick when releaseGradesStatus is SELECTED_GRADES_FROM_UNAVAILABLE_GRADERS', () => {
      props.releaseGradesStatus = SELECTED_GRADES_FROM_UNAVAILABLE_GRADERS
      render(<ReleaseButton {...props} />)
      fireEvent.click(screen.getByRole('button'))
      expect(props.onClick).not.toHaveBeenCalled()
    })
  })
})

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
import {render, screen} from '@testing-library/react'
import {FAILURE, STARTED} from '../../assignment/AssignmentActions'
import PostToStudentsButton from '../PostToStudentsButton'
import userEvent from '@testing-library/user-event'

describe('GradeSummary PostToStudentsButton', () => {
  let props
  let wrapper

  beforeEach(() => {
    props = {
      assignment: {
        gradesPublished: true,
        muted: true,
      },
      onClick: jest.fn(),
      unmuteAssignmentStatus: null,
    }
  })

  function mountComponent() {
    wrapper = render(<PostToStudentsButton {...props} />)
  }

  describe('when grades have not been released', () => {
    beforeEach(() => {
      props.assignment.gradesPublished = false
      mountComponent()
    })

    test('is labeled with "Post to Students"', () => {
      expect(screen.getByRole('button', {name: 'Post to Students'})).toBeInTheDocument
    })

    test('is disabled', () => {
      expect(screen.getByRole('button', {name: 'Post to Students'}).disabled).toBe(true)
    })

    test('does not call the onClick prop when clicked', async () => {
      const user = userEvent.setup({delay: null})
      await user.click(screen.getByRole('button', {name: 'Post to Students'}))
      expect(props.onClick).toHaveBeenCalledTimes(0)
    })
  })

  describe('when grades are not yet posted to students', () => {
    beforeEach(() => {
      mountComponent()
    })

    test('is labeled with "Post to Students"', () => {
      expect(screen.getByRole('button', {name: 'Post to Students'})).toBeInTheDocument
    })

    test('is not read-only', () => {
      expect(
        screen.getByRole('button', {name: 'Post to Students'}).getAttribute('aria-readonly')
      ).not.toBe('true')
    })

    test('calls the onClick prop when clicked', async () => {
      const user = userEvent.setup({delay: null})
      await user.click(screen.getByRole('button', {name: 'Post to Students'}))
      expect(props.onClick).toHaveBeenCalledTimes(1)
    })
  })

  describe('when grades are being posted to students', () => {
    beforeEach(() => {
      props.unmuteAssignmentStatus = STARTED
      mountComponent()
    })

    test('is labeled with "Posting to Students"', () => {
      expect(screen.getByRole('button', {name: 'Posting to Students'})).toBeInTheDocument
    })

    test('is read-only', () => {
      expect(
        screen.getByRole('button', {name: 'Posting to Students'}).getAttribute('aria-readonly')
      ).toBe('true')
    })

    test('does not call the onClick prop when clicked', async () => {
      const user = userEvent.setup({delay: null})
      await user.click(screen.getByRole('button', {name: 'Posting to Students'}))
      expect(props.onClick).toHaveBeenCalledTimes(0)
    })
  })

  describe('when grades are visible to students', () => {
    beforeEach(() => {
      props.assignment.muted = false
      mountComponent()
    })

    test('is labeled with "Grades Posted to Students"', () => {
      expect(screen.getByRole('button', {name: 'Grades Posted to Students'})).toBeInTheDocument
    })

    test('is read-only', () => {
      expect(
        screen
          .getByRole('button', {name: 'Grades Posted to Students'})
          .getAttribute('aria-readonly')
      ).toBe('true')
    })

    test('does not call the onClick prop when clicked', async () => {
      const user = userEvent.setup({delay: null})
      await user.click(screen.getByRole('button', {name: 'Grades Posted to Students'}))
      expect(props.onClick).toHaveBeenCalledTimes(0)
    })
  })

  describe('when posting to students failed', () => {
    beforeEach(() => {
      props.unmuteAssignmentStatus = FAILURE
      mountComponent()
    })

    test('is labeled with "Post to Students"', () => {
      expect(screen.getByRole('button', {name: 'Post to Students'})).toBeInTheDocument
    })

    test('is not read-only', () => {
      expect(
        screen.getByRole('button', {name: 'Post to Students'}).getAttribute('aria-readonly')
      ).toBe('false')
    })

    test('calls the onClick prop when clicked', async () => {
      const user = userEvent.setup({delay: null})
      screen.debug()
      await user.click(screen.getByRole('button', {name: 'Post to Students'}))
      expect(props.onClick).toHaveBeenCalledTimes(1)
    })
  })
})

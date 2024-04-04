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
import {render} from '@testing-library/react'
import ModeratedGradingCheckbox from '../ModeratedGradingCheckbox'
import userEvent from '@testing-library/user-event'

describe('ModeratedGradingCheckbox', () => {
  let props
  let wrapper

  beforeEach(() => {
    props = {
      checked: false,
      gradedSubmissionsExist: false,
      isGroupAssignment: false,
      isPeerReviewAssignment: false,
      onChange: () => {},
    }
  })

  function mountComponent() {
    wrapper = render(<ModeratedGradingCheckbox {...props} />)
  }

  function checkbox() {
    return wrapper.container.querySelector('input#assignment_moderated_grading[type="checkbox"]')
  }

  test('renders a Moderated Grading checkbox', () => {
    mountComponent()
    expect(checkbox()).toBeInTheDocument()
  })

  test('renders an unchecked checkbox when passed checked: false', () => {
    mountComponent()
    expect(checkbox().checked).toBe(false)
  })

  test('renders a checked checkbox when passed checked: true', () => {
    props.checked = true
    mountComponent()
    expect(checkbox().checked).toBe(true)
  })

  test(
    'enables the checkbox if no graded submissions exist, it is not a peer ' +
      'review assignment, and it is not a group assignment',
    () => {
      mountComponent()
      expect(checkbox().disabled).toBe(false)
    }
  )

  test('disables the checkbox if graded submissions exist', () => {
    props.gradedSubmissionsExist = true
    mountComponent()
    expect(checkbox().disabled).toBe(true)
  })

  test('disables the checkbox if it is a peer review assignment', () => {
    props.isPeerReviewAssignment = true
    mountComponent()
    expect(checkbox().disabled).toBe(true)
  })

  test('disables the checkbox if it is a group assignment', () => {
    props.isGroupAssignment = true
    mountComponent()
    expect(checkbox().disabled).toBe(true)
  })

  test('calls onChange when checked', async () => {
    const user = userEvent.setup()
    props.onChange = jest.fn()
    mountComponent()
    await user.click(checkbox())
    expect(props.onChange).toHaveBeenCalledTimes(1)
  })

  test('calls onChange with `true` when being checked', async () => {
    const user = userEvent.setup()
    props.onChange = jest.fn()
    mountComponent()
    await user.click(checkbox())
    expect(props.onChange).toHaveBeenCalledWith(true)
  })

  test('calls onChange with `false` when being unchecked', async () => {
    const user = userEvent.setup()
    props.checked = true
    props.onChange = jest.fn()
    mountComponent()
    await user.click(checkbox())
    expect(props.onChange).toHaveBeenCalledWith(false)
  })
})

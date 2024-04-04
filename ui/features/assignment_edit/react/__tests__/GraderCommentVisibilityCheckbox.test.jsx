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
import GraderCommentVisibilityCheckbox from '../GraderCommentVisibilityCheckbox'
import userEvent from '@testing-library/user-event'

describe('GraderCommentVisibilityCheckbox', () => {
  let props
  let wrapper

  beforeEach(() => {
    props = {
      checked: false,
      onChange() {},
    }
  })

  function mountComponent() {
    wrapper = render(<GraderCommentVisibilityCheckbox {...props} />)
  }

  function checkbox() {
    return wrapper.container.querySelector('input#assignment_grader_comment_visibility')
  }

  function formField() {
    return wrapper.container.querySelector('input[name="grader_comments_visible_to_graders"]')
  }

  test('renders a checkbox', () => {
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

  test('sets the value of the form input to "false" when passed checked: false', () => {
    mountComponent()
    expect(formField().value).toBe('false')
  })

  test('sets the value of the form input to "true" when passed checked: true', () => {
    props.checked = true
    mountComponent()
    expect(formField().value).toBe('true')
  })

  test('checking the checkbox updates the value of the form input', async () => {
    const user = userEvent.setup()
    mountComponent()
    await user.click(checkbox())
    expect(formField().value).toBe('true')
  })

  test('unchecking the checkbox updates the value of the form input', async () => {
    props.checked = true
    const user = userEvent.setup()
    mountComponent()
    await user.click(checkbox())
    expect(formField().value).toBe('false')
  })

  test('checking the checkbox calls onChange', async () => {
    props.onChange = jest.fn()
    const user = userEvent.setup()
    mountComponent()
    await user.click(checkbox())
    expect(props.onChange).toHaveBeenCalledTimes(1)
  })

  test('unchecking the checkbox calls onChange', async () => {
    props.checked = true
    props.onChange = jest.fn()
    const user = userEvent.setup()
    mountComponent()
    await user.click(checkbox())
    expect(props.onChange).toHaveBeenCalledTimes(1)
  })
})

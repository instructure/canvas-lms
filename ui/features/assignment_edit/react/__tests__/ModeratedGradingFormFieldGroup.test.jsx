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
import ModeratedGradingFormFieldGroup from '../ModeratedGradingFormFieldGroup'
import userEvent from '@testing-library/user-event'

describe('ModeratedGradingFormFieldGroup', () => {
  let props
  let wrapper

  beforeEach(() => {
    props = {
      availableModerators: [
        {name: 'John Doe', id: '923'},
        {name: 'Jane Doe', id: '492'},
      ],
      finalGraderID: undefined,
      graderCommentsVisibleToGraders: true,
      graderNamesVisibleToFinalGrader: true,
      gradedSubmissionsExist: false,
      isGroupAssignment: false,
      isPeerReviewAssignment: false,
      locale: 'en',
      availableGradersCount: 10,
      moderatedGradingEnabled: true,
      onGraderCommentsVisibleToGradersChange() {},
      onModeratedGradingChange() {},
    }
  })

  function mountComponent() {
    wrapper = render(<ModeratedGradingFormFieldGroup {...props} />)
  }

  function content() {
    return wrapper.container.querySelector('.ModeratedGrading__Content')
  }

  test('hides the moderated grading content when passed moderatedGradingEnabled: false', () => {
    props.moderatedGradingEnabled = false
    mountComponent()
    expect(content()).not.toBeInTheDocument()
  })

  test('shows the moderated grading content when passed moderatedGradingEnabled: true', () => {
    mountComponent()
    expect(content()).toBeInTheDocument()
  })

  test('includes a final grader select menu in the moderated grading content', () => {
    mountComponent()
    const selectMenu = content().querySelector('select[name="final_grader_id"]')
    expect(selectMenu).toBeInTheDocument()
  })

  test('includes a grader count input in the moderated grading content', () => {
    mountComponent()
    const graderCountInput = content().querySelector(
      '.ModeratedGrading__GraderCountInputContainer input'
    )
    expect(graderCountInput).toBeInTheDocument()
  })

  describe('Moderated Grading Checkbox', () => {
    function moderatedGradingCheckbox() {
      return wrapper.container.querySelector('input#assignment_moderated_grading[type="checkbox"]')
    }

    test('renders the checkbox', () => {
      mountComponent()
      expect(moderatedGradingCheckbox()).toBeInTheDocument()
    })

    test('renders an unchecked checkbox when passed moderatedGradingEnabled: false', () => {
      props.moderatedGradingEnabled = false
      mountComponent()
      expect(moderatedGradingCheckbox().checked).toBe(false)
    })

    test('renders a checked checkbox when passed moderatedGradingEnabled: true', () => {
      mountComponent()
      expect(moderatedGradingCheckbox().checked).toBe(true)
    })

    test('hides the moderated grading content when the checkbox is unchecked', async () => {
      const user = userEvent.setup()
      mountComponent()
      await user.click(moderatedGradingCheckbox())
      expect(content()).not.toBeInTheDocument()
    })

    test('shows the moderated grading content when the checkbox is checked', async () => {
      const user = userEvent.setup()
      props.moderatedGradingEnabled = false
      mountComponent()
      await user.click(moderatedGradingCheckbox())
      expect(content()).toBeInTheDocument()
    })

    test('calls onModeratedGradingChange when the checkbox is checked', async () => {
      const user = userEvent.setup()
      props.moderatedGradingEnabled = false
      props.onModeratedGradingChange = jest.fn()
      mountComponent()
      await user.click(moderatedGradingCheckbox())
      expect(props.onModeratedGradingChange).toHaveBeenCalledTimes(1)
    })

    test('calls onModeratedGradingChange when the checkbox is unchecked', async () => {
      const user = userEvent.setup()
      props.onModeratedGradingChange = jest.fn()
      mountComponent()
      await user.click(moderatedGradingCheckbox())
      expect(props.onModeratedGradingChange).toHaveBeenCalledTimes(1)
    })
  })

  describe('Grader Comment Visibility Checkbox', () => {
    function graderCommentsVisibleToGradersCheckbox() {
      return wrapper.container.querySelector('input#assignment_grader_comment_visibility')
    }

    test('renders the checkbox', () => {
      mountComponent()
      expect(graderCommentsVisibleToGradersCheckbox()).toBeInTheDocument()
    })

    test('renders an unchecked checkbox when passed graderCommentsVisibleToGraders: false', () => {
      props.graderCommentsVisibleToGraders = false
      mountComponent()
      expect(graderCommentsVisibleToGradersCheckbox().checked).toBe(false)
    })

    test('renders a checked checkbox when passed graderCommentsVisibleToGraders: true', () => {
      mountComponent()
      expect(graderCommentsVisibleToGradersCheckbox().checked).toBe(true)
    })
  })

  describe('Grader Names Visible to Final Grader Checkbox', () => {
    function graderNamesVisibleToFinalGraderCheckbox() {
      return wrapper.container.querySelector(
        'input#assignment_grader_names_visible_to_final_grader'
      )
    }

    test('renders a grader names visible to final grader checkbox in the moderated grading content', () => {
      mountComponent()
      expect(graderNamesVisibleToFinalGraderCheckbox()).toBeInTheDocument()
    })

    test('renders an unchecked checkbox when passed graderNamesVisibleToFinalGrader: false', () => {
      props.graderNamesVisibleToFinalGrader = false
      mountComponent()
      expect(graderNamesVisibleToFinalGraderCheckbox().checked).toBe(false)
    })

    test('renders a checked checkbox for Moderated Grading when passed graderNamesVisibleToFinalGrader: true', () => {
      mountComponent()
      expect(graderNamesVisibleToFinalGraderCheckbox().checked).toBe(true)
    })
  })
})

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
import userEvent from '@testing-library/user-event'
import GradePostingPolicyTabPanel from '../GradePostingPolicyTabPanel'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'

jest.mock('@canvas/alerts/react/FlashAlert')

describe('GradePostingPolicyTabPanel', () => {
  const defaultProps = {
    anonymousAssignmentsPresent: true,
    gradebookIsEditable: true,
    onChange: jest.fn(),
    settings: {
      postManually: false,
    },
  }

  beforeEach(() => {
    FlashAlert.showFlashAlert.mockClear()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  const renderComponent = (props = {}) => {
    return render(<GradePostingPolicyTabPanel {...defaultProps} {...props} />)
  }

  it('renders the component', () => {
    renderComponent()
    expect(screen.getByRole('radiogroup')).toBeInTheDocument()
  })

  describe('Course Post Policies', () => {
    const getAutomaticRadio = () =>
      screen.getByRole('radio', {
        name: /Automatically Post Grades Assignment grades will be visible to students/i,
        hidden: true,
      })

    const getManualRadio = () =>
      screen.getByRole('radio', {
        name: /Manually Post Grades Grades will be hidden by default/i,
        hidden: true,
      })

    describe('when postManually is false', () => {
      it('selects automatic posting', () => {
        renderComponent()
        expect(getAutomaticRadio()).toBeChecked()
      })
    })

    describe('when postManually is true', () => {
      it('selects manual posting', () => {
        renderComponent({settings: {postManually: true}})
        expect(getManualRadio()).toBeChecked()
      })
    })

    describe('when gradebook is not editable', () => {
      it('disables both radio buttons', () => {
        renderComponent({gradebookIsEditable: false})
        expect(getAutomaticRadio()).toBeDisabled()
        expect(getManualRadio()).toBeDisabled()
      })
    })

    describe('when gradebook is editable', () => {
      it('enables both radio buttons', () => {
        renderComponent({gradebookIsEditable: true})
        expect(getAutomaticRadio()).toBeEnabled()
        expect(getManualRadio()).toBeEnabled()
      })
    })

    describe('onChange behavior', () => {
      it('calls onChange when automatic posting is selected', async () => {
        const onChange = jest.fn()
        renderComponent({onChange, settings: {postManually: true}})
        await userEvent.click(getAutomaticRadio())
        expect(onChange).toHaveBeenCalled()
      })

      it('calls onChange when manual posting is selected', async () => {
        const onChange = jest.fn()
        renderComponent({onChange})
        await userEvent.click(getManualRadio())
        expect(onChange).toHaveBeenCalled()
      })
    })

    describe('flash alerts', () => {
      it('shows flash alert when selecting automatic posting with anonymous assignments', async () => {
        renderComponent({settings: {postManually: true}, anonymousAssignmentsPresent: true})
        await userEvent.click(getAutomaticRadio())
        expect(FlashAlert.showFlashAlert).toHaveBeenCalled()
      })

      it('does not show flash alert when selecting automatic posting without anonymous assignments', async () => {
        renderComponent({settings: {postManually: true}, anonymousAssignmentsPresent: false})
        await userEvent.click(getAutomaticRadio())
        expect(FlashAlert.showFlashAlert).not.toHaveBeenCalled()
      })
    })
  })
})

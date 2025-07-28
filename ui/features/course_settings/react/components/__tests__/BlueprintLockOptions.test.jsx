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
import BlueprintLockOptions from '../BlueprintLockOptions'

const defaultProps = {
  isMasterCourse: false,
  disabledMessage: '',
  useRestrictionsbyType: false,
  generalRestrictions: {
    content: false,
    points: false,
    due_dates: false,
    availability_dates: false,
  },
  restrictionsByType: {
    assignment: {content: false, points: false, due_dates: false, availability_dates: false},
    discussion_topic: {content: false, points: false, due_dates: false, availability_dates: false},
    wiki_page: {content: false, points: false, due_dates: false, availability_dates: false},
    quiz: {content: false, points: false, due_dates: false, availability_dates: false},
    attachment: {content: false, points: false, due_dates: false, availability_dates: false},
  },
  lockableAttributes: ['content', 'points', 'due_dates', 'availability_dates'],
}

describe('BlueprintLockOptions', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders the blueprint checkbox', () => {
    render(<BlueprintLockOptions {...defaultProps} />)
    expect(screen.getByLabelText(/Enable course as a Blueprint Course/i)).toBeInTheDocument()
  })

  it('hides radio options when blueprint checkbox is unchecked', () => {
    const {container} = render(<BlueprintLockOptions {...defaultProps} />)

    const radioContainer = container.querySelector('.bcs_sub-menu')
    expect(radioContainer).not.toHaveClass('bcs_sub-menu-viewable')
  })

  it('shows the general menu when master course is enabled and using general restrictions', async () => {
    const user = userEvent.setup()
    render(<BlueprintLockOptions {...defaultProps} isMasterCourse={true} />)

    const checkbox = screen.getByLabelText(/Enable course as a Blueprint Course/i)
    await user.click(checkbox)

    expect(screen.getByLabelText(/General Locked Objects/i)).toBeInTheDocument()
    expect(
      screen.getByText(/Define general settings for locked objects in this course/i),
    ).toBeInTheDocument()
  })

  it('shows the granular menu when master course is enabled and using restrictions by type', async () => {
    const user = userEvent.setup()
    render(
      <BlueprintLockOptions {...defaultProps} isMasterCourse={true} useRestrictionsbyType={true} />,
    )

    const checkbox = screen.getByLabelText(/Enable course as a Blueprint Course/i)
    await user.click(checkbox)

    expect(screen.getByLabelText(/Locked Objects by Type/i)).toBeInTheDocument()
    expect(
      screen.getByText(/Define settings by type for locked objects in this course/i),
    ).toBeInTheDocument()
  })

  it('disables the checkbox when a disabled message is provided', () => {
    const disabledMessage = 'This is a disabled message'
    render(<BlueprintLockOptions {...defaultProps} disabledMessage={disabledMessage} />)

    const checkbox = screen.getByLabelText(disabledMessage)
    expect(checkbox).toBeDisabled()
    expect(checkbox).toHaveAttribute('aria-label', disabledMessage)
  })
})

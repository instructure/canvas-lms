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
import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import CriterionInfo from '../CriterionInfo'

describe('The CriterionInfo component', () => {
  it('renders an info button that toggles a modal with help content', async () => {
    const user = userEvent.setup()
    const {getByRole, queryByRole, getByText} = render(<CriterionInfo />)

    // Initially should show just the info button
    const infoButton = getByRole('button', {name: 'More Information About Ratings'})
    expect(infoButton).toBeInTheDocument()
    expect(queryByRole('dialog')).not.toBeInTheDocument()

    // Click the button to open modal
    await user.click(infoButton)

    // Should now show the modal
    const modal = getByRole('dialog')
    expect(modal).toBeInTheDocument()
    expect(modal).toHaveAttribute('aria-label', 'Criterion Ratings')

    // Check modal content
    expect(getByRole('heading', {name: 'Criterion Ratings', level: 2})).toBeInTheDocument()
    expect(getByText(/Learning outcomes can be included in assignment rubrics/)).toBeInTheDocument()
    expect(getByText(/define mastery of this outcome/)).toBeInTheDocument()

    // Check that close button is present
    expect(getByRole('button', {name: /close/i})).toBeInTheDocument()
  })
})

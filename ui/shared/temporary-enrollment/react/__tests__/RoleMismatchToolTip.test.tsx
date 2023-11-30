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
import {fireEvent, render, screen} from '@testing-library/react'
import RoleMismatchToolTip from '../RoleMismatchToolTip'

const toolTipText =
  'Enrolling the recipient in these courses will grant them different permissions from the provider of the enrollments'

describe('RoleMismatchToolTip', () => {
  it('displays tooltip text when hovered', async () => {
    const testId = 'role-mismatch-tooltip'
    render(<RoleMismatchToolTip testId={testId} />)
    fireEvent.mouseOver(screen.getByTestId(testId))
    expect(screen.getByText(toolTipText)).toBeInTheDocument()
  })

  it('displays tooltip text when focused', async () => {
    const testId = 'role-mismatch-tooltip'
    render(<RoleMismatchToolTip testId={testId} />)
    fireEvent.focus(screen.getByTestId(testId))
    expect(screen.getByText(toolTipText)).toBeInTheDocument()
  })

  it('has appropriate aria attributes for accessibility', async () => {
    const testId = 'role-mismatch-tooltip'
    render(<RoleMismatchToolTip testId={testId} />)
    expect(screen.getByTestId(testId)).toHaveAttribute('aria-describedby')
  })
})

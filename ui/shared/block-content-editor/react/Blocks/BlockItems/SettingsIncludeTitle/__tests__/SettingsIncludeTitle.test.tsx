/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {render, fireEvent} from '@testing-library/react'
import {SettingsIncludeTitle} from '../SettingsIncludeTitle'
import {SettingsIncludeTitleProps} from '../types'

describe('SettingsIncludeTitle', () => {
  const defaultProps: SettingsIncludeTitleProps = {
    checked: false,
    onChange: vi.fn(),
  }

  it('renders the checkbox with correct label', () => {
    const component = render(<SettingsIncludeTitle {...defaultProps} />)
    expect(component.getByLabelText(/Include block title/i)).not.toBeChecked()
  })

  it('reflects checked state', () => {
    const component = render(<SettingsIncludeTitle {...defaultProps} checked={true} />)
    expect(component.getByLabelText(/Include block title/i)).toBeChecked()
  })

  it('calls onChange when toggled', () => {
    const component = render(<SettingsIncludeTitle {...defaultProps} />)
    fireEvent.click(component.getByLabelText(/Include block title/i))
    expect(defaultProps.onChange).toHaveBeenCalled()
  })
})

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

import {render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import LicenseHelpIcon from '../LicenseHelpIcon'

const renderWithSelect = (selected: string) => {
  return (
    <>
      <select id="course_license" data-testid="course_license" defaultValue={selected}>
        <option value="private"></option>
        <option value="cc_by"></option>
        <option value="cc_by_sa"></option>
        <option value="cc_by_nc"></option>
        <option value="cc_by_nc_sa"></option>
        <option value="cc_by_nc_nd"></option>
      </select>
      <LicenseHelpIcon />
    </>
  )
}

describe('LicenseHelpIcon', () => {
  it('does not throw errors if the license select is missing', () => {
    expect(() => {
      render(<LicenseHelpIcon />)
    }).not.toThrow()
  })

  it('renders with currently selected license', async () => {
    const user = userEvent.setup()
    const {getByText, getByTestId, getAllByTestId} = render(renderWithSelect('cc_by_nc_sa'))

    await user.click(getByTestId('license_help_link'))

    expect(getByText('Content Licensing Help')).toBeInTheDocument()
    await waitFor(() => {
      expect(getByText('CC Attribution Non-Commercial Share Alike')).toBeInTheDocument()
    })
    const selected = getAllByTestId(/selected_/)
    expect(selected).toHaveLength(3)
    expect(getByTestId('no_derivative_works')).toBeInTheDocument()
  })

  it('changes license recommendations based on selected preferences', async () => {
    const user = userEvent.setup()
    const {getByText, getByTestId, getAllByTestId} = render(renderWithSelect('private'))

    await user.click(getByTestId('license_help_link'))

    expect(getByText('Private (Copyrighted)')).toBeInTheDocument()

    await user.click(getByTestId('attribution'))

    await waitFor(() => {
      expect(getByText('CC Attribution')).toBeInTheDocument()
    })
    expect(getAllByTestId(/selected_/)).toHaveLength(1)
    expect(getByTestId('selected_attribution')).toBeInTheDocument()
  })

  it('updates the license select when "Use This License" is clicked', async () => {
    const user = userEvent.setup()
    const {getByText, getByTestId} = render(renderWithSelect('cc_by_nc_nd'))

    await user.click(getByTestId('license_help_link'))
    await user.click(getByTestId('share_alike'))

    await waitFor(() => {
      expect(getByText('CC Attribution Non-Commercial Share Alike')).toBeInTheDocument()
    })
    await user.click(getByTestId('use_this_license'))
    await waitFor(() => {
      expect(getByTestId('course_license')).toHaveValue('cc_by_nc_sa')
    })
  })
})

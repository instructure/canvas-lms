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
import {render, fireEvent, waitFor} from '@testing-library/react'
import {mockOverride} from '../../../test-utils'
import Override from '../Override'

function renderOverride(override, props = {}) {
  return render(
    <Override
      override={override}
      onChangeOverride={() => {}}
      index={0}
      onValidate={() => true}
      invalidMessage={() => undefined}
      {...props}
    />
  )
}

describe('Override', () => {
  it('renders an override', () => {
    const override = mockOverride()
    const {getByTestId} = renderOverride(override)
    expect(getByTestId('OverrideSummary')).toBeInTheDocument()
  })

  it('displays OverrideDetail on expanding toggle group', async () => {
    const override = mockOverride()
    const {getByText, getByTestId} = renderOverride(override)

    const expandButton = getByText('Click to show details')
    fireEvent.click(expandButton)
    // the detail is now rendered
    const detail = await waitFor(() => getByTestId('OverrideDetail'))
    expect(detail).toBeInTheDocument()
    // and the summary's still there
    expect(getByTestId('OverrideSummary')).toBeInTheDocument()
  })
})

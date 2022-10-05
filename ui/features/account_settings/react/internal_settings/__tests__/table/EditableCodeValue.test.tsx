/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {EditableCodeValue} from '../../table/EditableCodeValue'
import {render} from '@testing-library/react'

const callback = jest.fn()

describe('EditableCodeValue', () => {
  it('has a button with an appropriate screen reader label', () => {
    const {getByRole, rerender} = render(<EditableCodeValue onValueChange={callback} value="" />)

    expect(getByRole('button')).toHaveTextContent('Edit value')

    rerender(<EditableCodeValue onValueChange={callback} value="" name="Best setting" />)
    expect(getByRole('button')).toHaveTextContent('Edit value for "Best setting"')

    rerender(
      <EditableCodeValue
        onValueChange={callback}
        value=""
        screenReaderLabel="Custom screen reader label"
      />
    )
    expect(getByRole('button')).toHaveTextContent('Custom screen reader label')
  })

  it('obscures secret values', () => {
    const {getByText} = render(
      <EditableCodeValue onValueChange={callback} value="value" secret={true} />
    )

    expect(getByText('*'.repeat(24))).toBeInTheDocument()
  })

  it('displays a placeholder if one is provided', () => {
    const {getByText} = render(
      <EditableCodeValue onValueChange={callback} value="value" placeholder={<p>New setting</p>} />
    )

    expect(getByText('New setting')).toBeInTheDocument()
  })
})

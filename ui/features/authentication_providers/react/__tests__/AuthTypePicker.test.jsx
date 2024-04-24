/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import {render, cleanup} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import AuthTypePicker from '../AuthTypePicker'

const authTypes = [
  {name: 'TypeOne', value: '1'},
  {name: 'TypeTwo', value: '2'},
]

const renderAuthTypePicker = props => {
  const activeProps = {
    authTypes,
    ...props,
  }

  return render(<AuthTypePicker {...activeProps} />)
}

describe('AuthTypePicker', () => {
  afterEach(() => {
    cleanup()
  })

  it('rendered structure', () => {
    const wrapper = renderAuthTypePicker()

    expect(wrapper.container.querySelectorAll('option')).toHaveLength(2)
  })

  it('choosing an auth type fires the provided callback', async () => {
    const spy = jest.fn()
    const wrapper = renderAuthTypePicker({onChange: spy})

    await userEvent.selectOptions(wrapper.getByRole('combobox'), authTypes[1].name)

    expect(spy).toHaveBeenCalledWith(authTypes[1].value)
  })
})

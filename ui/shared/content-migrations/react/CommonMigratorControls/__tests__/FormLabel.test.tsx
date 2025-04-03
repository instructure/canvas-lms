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
import {FormLabel, RequiredFormLabel} from '../FormLabel'

describe('FormLabel', () => {
  it('renders the label text', () => {
    const {getByText} = render(<FormLabel>Test Label</FormLabel>)
    expect(getByText('Test Label')).toBeInTheDocument()
  })
})

describe('RequiredFormLabel', () => {
  it('renders the label text with an asterisk', () => {
    const {getByText} = render(
      <RequiredFormLabel showErrorState={false}>Test Label</RequiredFormLabel>,
    )
    expect(getByText('Test Label')).toBeInTheDocument()
    expect(getByText('*')).toBeInTheDocument()
  })

  it('displays the asterisk in primary color when showErrorState is false', () => {
    const {getByText} = render(
      <RequiredFormLabel showErrorState={false}>Test Label</RequiredFormLabel>,
    )
    expect(getByText('*')).toHaveStyle('color: rgb(39, 53, 64)')
  })

  it('displays the asterisk in danger color when showErrorState is true', () => {
    const {getByText} = render(
      <RequiredFormLabel showErrorState={true}>Test Label</RequiredFormLabel>,
    )
    expect(getByText('*')).toHaveStyle('color: rgb(199, 31, 35)')
  })
})

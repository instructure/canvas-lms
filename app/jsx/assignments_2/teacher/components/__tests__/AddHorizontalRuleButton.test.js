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
import AddHorizontalRuleButton from '../AddHorizontalRuleButton'

it('renders', () => {
  const {getByText, getByTestId} = render(
    <AddHorizontalRuleButton onClick={() => {}} label="click me" />
  )
  expect(getByTestId('AddHorizontalRuleButton')).toBeInTheDocument()
  expect(getByText('click me')).toBeInTheDocument()
})

it('calls onClick when clicked', () => {
  const onclick = jest.fn()
  const {getByText} = render(<AddHorizontalRuleButton onClick={onclick} label="click me" />)

  const btn = getByText('click me')
  btn.click()
  expect(onclick).toHaveBeenCalled()
})

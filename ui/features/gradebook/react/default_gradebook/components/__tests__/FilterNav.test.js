/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {Default as FilterNav} from '../FilterNav.stories'
import {render, fireEvent, within, cleanup, screen} from '@testing-library/react'
import '@testing-library/jest-dom/extend-expect'

describe('FilterNav', () => {
  it('renders filters button', () => {
    const {getByRole} = render(<FilterNav {...FilterNav.args} />)
    expect(getByRole('button', {name: 'Filters'})).toBeInTheDocument()
  })

  it('opens tray', () => {
    const {container} = render(<FilterNav {...FilterNav.args} />)
    fireEvent.click(within(container).getByText('Filters'))
    expect(screen.getByRole('heading')).toHaveTextContent('Gradebook Filters')
    cleanup()
  })

  it('renders new filter button', () => {
    const {container} = render(<FilterNav {...FilterNav.args} />)
    fireEvent.click(within(container).getByText('Filters'))
    expect(screen.getByRole('button', {name: /Create New Filter/})).toBeInTheDocument()
    cleanup()
  })
})

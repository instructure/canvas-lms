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
import AllContextsNameLink from '../AllContextsNameLink'
import {render, screen} from '@testing-library/react'
import {BrowserRouter} from 'react-router-dom'

const defaultProps = {
  name: 'My Context',
  contextType: 'courses',
  contextId: '1',
}

const renderComponent = (props: any) => {
  return render(
    <BrowserRouter>
      <AllContextsNameLink {...defaultProps} {...props} />
    </BrowserRouter>,
  )
}

describe('AllContextsNameLink', () => {
  it('renders correct course link', () => {
    renderComponent({contextType: 'courses'})
    const link = screen.getByRole('link', {name: /my context/i})
    expect(link).toHaveAttribute('href', '/folder/courses_1')
  })

  it('renders correct user link', () => {
    renderComponent({contextType: 'users'})
    const link = screen.getByRole('link', {name: /my context/i})
    expect(link).toHaveAttribute('href', '/folder/users_1')
  })
})

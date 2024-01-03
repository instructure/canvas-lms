/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {BrowserRouter} from 'react-router-dom'
import {render} from '@testing-library/react'
import {QueryProvider} from '@canvas/query'
import {RubricForm} from '../index'

describe('RubricForm Tests', () => {
  const renderComponent = () => {
    return render(
      <QueryProvider>
        <BrowserRouter>
          <RubricForm />
        </BrowserRouter>
      </QueryProvider>
    )
  }

  it('renders component', () => {
    const {getByText} = renderComponent()

    expect(getByText('Create New Rubric')).toBeInTheDocument()
  })
})

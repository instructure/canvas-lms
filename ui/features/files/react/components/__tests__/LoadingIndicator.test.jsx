/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import LoadingIndicator from '../LoadingIndicator'

describe('LoadingIndicator', () => {
  test('display none if no props supplied', () => {
    const {container} = render(<LoadingIndicator />)
    expect(container.firstChild).toHaveStyle('display: none')
  })

  test('if props supplied for loading', () => {
    const {container} = render(<LoadingIndicator isLoading />)
    expect(container.firstChild).not.toHaveStyle('display: none')
  })
})

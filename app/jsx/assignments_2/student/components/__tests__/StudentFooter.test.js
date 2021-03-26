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
import {render} from '@testing-library/react'
import StudentFooter from '../StudentFooter'

it('renders passed-in elements in order', async () => {
  const buttons = [
    {key: 'item1', element: <div data-testid="child-item">item 1</div>},
    {key: 'item2', element: <div data-testid="child-item">item 2</div>}
  ]

  const {getAllByTestId} = render(<StudentFooter buttons={buttons} />)
  expect(getAllByTestId('child-item').map(element => element.innerHTML)).toEqual([
    'item 1',
    'item 2'
  ])
})

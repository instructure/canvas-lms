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
import FileNotFound from '../FileNotFound'

describe('FileNotFound Component', () => {
  test('it renders', () => {
    const {getByText, unmount} = render(<FileNotFound contextCode="fakeContextCode" />)

    // If you have specific text or elements to check that render, use `getByText` or similar queries.
    // For example, if 'File Not Found' text should be present, uncomment the next line:
    // expect(getByText('File Not Found')).toBeInTheDocument();

    // Jest and React Testing Library automatically clean up after each test, but you can also manually unmount if needed:
    unmount()
  })
})

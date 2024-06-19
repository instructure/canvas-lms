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
import {render, screen} from '@testing-library/react'
import NoResults from '../NoResults'

describe('NoResults', () => {
  it('displays search term in no results text', () => {
    const searchTerm = 'texas toast'
    render(<NoResults search_term={searchTerm} />)
    const expectedText = `Your search - "${searchTerm}" - did not match any files.`
    expect(screen.getByText(expectedText)).toBeInTheDocument()
  })
})

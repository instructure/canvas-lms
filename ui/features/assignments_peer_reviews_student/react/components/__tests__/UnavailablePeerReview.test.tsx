/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import UnavailablePeerReview from '../UnavailablePeerReview'

describe('UnavailablePeerReview', () => {
  it('renders the unavailable peer review message', () => {
    render(<UnavailablePeerReview />)

    expect(
      screen.getByText(
        'There are no more peer reviews available to allocate to you at this time. Check back later or contact your instructor.',
      ),
    ).toBeInTheDocument()
  })

  it('renders the unavailable peer review image', () => {
    render(<UnavailablePeerReview />)

    const image = screen.getByAltText('No peer reviews available')
    expect(image).toBeInTheDocument()
  })
})

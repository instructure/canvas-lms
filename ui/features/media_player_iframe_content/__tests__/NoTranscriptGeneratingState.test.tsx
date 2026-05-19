/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {render, screen} from '@testing-library/react'
import {NoTranscriptGeneratingState} from '../components/NoTranscriptGeneratingState'

describe('<NoTranscriptGeneratingState />', () => {
  it('renders the generating headline', () => {
    render(<NoTranscriptGeneratingState />)

    expect(screen.getByText('Captions are being generated for this media.')).toBeInTheDocument()
  })

  it('renders the 24 hours sub-text', () => {
    render(<NoTranscriptGeneratingState />)

    expect(screen.getByText('This may take up to 24 hours.')).toBeInTheDocument()
  })
})

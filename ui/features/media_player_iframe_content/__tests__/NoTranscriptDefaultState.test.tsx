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
import {NoTranscriptDefaultState} from '../components/NoTranscriptDefaultState'

describe('<NoTranscriptDefaultState />', () => {
  it('renders the no transcript message', () => {
    render(<NoTranscriptDefaultState canManageTranscripts={false} />)

    expect(screen.getByText('There is no transcript yet.')).toBeInTheDocument()
  })

  it('renders the upload hint text when canManageTranscripts is true', () => {
    render(<NoTranscriptDefaultState canManageTranscripts={true} />)

    expect(screen.getByText('Request or upload to show transcript.')).toBeInTheDocument()
  })

  it('does not render the upload hint text when canManageTranscripts is false', () => {
    render(<NoTranscriptDefaultState canManageTranscripts={false} />)

    expect(screen.queryByText('Request or upload to show transcript.')).not.toBeInTheDocument()
  })
})

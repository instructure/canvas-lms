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
import {render} from '@testing-library/react'
import AssignmentDescription from '../AssignmentDescription'
import apiUserContent from '@canvas/util/jquery/apiUserContent'

vi.mock('@canvas/util/jquery/apiUserContent', () => ({
  default: {
    convert: vi.fn((content: string) => content),
  },
}))

describe('AssignmentDescription', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders with description prop', () => {
    const description = '<p>This is an assignment description</p>'
    const {getByTestId} = render(<AssignmentDescription description={description} />)

    const descriptionElement = getByTestId('assignments-2-assignment-description')
    expect(descriptionElement).toBeInTheDocument()
    expect(descriptionElement).toHaveClass('user_content')
  })

  it('renders fallback text when no description is provided', () => {
    const {getByTestId} = render(<AssignmentDescription />)

    const descriptionElement = getByTestId('assignments-2-assignment-description')
    expect(descriptionElement).toBeInTheDocument()
    expect(descriptionElement.innerHTML).toBe(
      'No additional details were added for this assignment.',
    )
  })

  it('renders fallback text when description is empty string', () => {
    const {getByTestId} = render(<AssignmentDescription description="" />)

    const descriptionElement = getByTestId('assignments-2-assignment-description')
    expect(descriptionElement).toBeInTheDocument()
    expect(descriptionElement.innerHTML).toBe(
      'No additional details were added for this assignment.',
    )
  })

  it('calls apiUserContent.convert when description is provided', () => {
    const description = '<p>Test description</p>'

    render(<AssignmentDescription description={description} />)

    expect(apiUserContent.convert).toHaveBeenCalledWith(description)
  })

  it('does not call apiUserContent.convert when no description is provided', () => {
    render(<AssignmentDescription />)

    expect(apiUserContent.convert).not.toHaveBeenCalled()
  })
})

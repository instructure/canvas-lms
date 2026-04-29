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
import CoursesTab from '../CoursesTab'

type Props = Record<string, never> // CoursesTab has no props

const setUp = (props: Props) => {
  return render(<CoursesTab {...props} />)
}

const buildDefaultProps = (overrides = {}): Props => {
  const defaultProps: Props = {}

  return {...defaultProps, ...overrides}
}

describe('CoursesTab', () => {
  it('should render with proper heading structure', () => {
    const {getByTestId} = setUp(buildDefaultProps())
    expect(getByTestId('courses-tab-heading')).toBeInTheDocument()
  })

  it('should have proper structure with InstUI components', () => {
    const {getByText} = setUp(buildDefaultProps())
    const container = getByText('Courses').closest('div')
    expect(container).toBeInTheDocument()
  })

  it('renders properly with default props', () => {
    const {container} = setUp(buildDefaultProps())
    expect(container).not.toBeEmptyDOMElement()
  })
})

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
import CoursePeopleApp from '../CoursePeopleApp'

const mockContextValue = {
  courseId: '1',
  canReadRoster: true,
}

jest.mock('../contexts/CoursePeopleContext', () => ({
  __esModule: true,
  default: {
    Provider: ({children, value}: {children: React.ReactNode; value: unknown}) => (
      <div data-testid="course-people-context-provider" data-context-value={JSON.stringify(value)}>
        {children}
      </div>
    ),
  },
  getCoursePeopleContext: jest.fn(() => mockContextValue),
}))

jest.mock('@canvas/error-boundary', () => ({
  __esModule: true,
  default: ({
    children,
    errorComponent,
  }: {children: React.ReactNode; errorComponent: React.ReactNode}) => (
    <div
      data-testid="error-boundary"
      data-error-component={errorComponent ? 'has-error-component' : undefined}
    >
      {children}
    </div>
  ),
}))

jest.mock('../CoursePeople', () => ({
  __esModule: true,
  default: () => <div data-testid="course-people" />,
}))

describe('CoursePeopleApp', () => {
  const renderComponent = () => render(<CoursePeopleApp />)

  beforeEach(() => {
    renderComponent()
  })

  it('renders CoursePeople component', () => {
    expect(screen.getByTestId('course-people')).toBeInTheDocument()
  })

  it('wraps CoursePeople in an ErrorBoundary component', () => {
    const errorBoundary = screen.getByTestId('error-boundary')
    expect(errorBoundary).toBeInTheDocument()
    expect(errorBoundary).toHaveAttribute('data-error-component', 'has-error-component')
    expect(errorBoundary).toContainElement(screen.getByTestId('course-people'))
  })

  it('wraps CoursePeople in CoursePeopleContext.Provider with correct context value', () => {
    const contextProvider = screen.getByTestId('course-people-context-provider')
    expect(contextProvider).toBeInTheDocument()
    expect(contextProvider).toContainElement(screen.getByTestId('course-people'))
    expect(contextProvider).toHaveAttribute('data-context-value', JSON.stringify(mockContextValue))
  })

  it('maintains correct component hierarchy', () => {
    const contextProvider = screen.getByTestId('course-people-context-provider')
    const errorBoundary = screen.getByTestId('error-boundary')
    const coursePeople = screen.getByTestId('course-people')

    expect(contextProvider).toContainElement(errorBoundary)
    expect(errorBoundary).toContainElement(coursePeople)
  })
})

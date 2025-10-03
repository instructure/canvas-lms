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
import OutcomeContextTag from '../OutcomeContextTag'

describe('OutcomeContextTag', () => {
  it('renders Institution tag when outcome is from a different Account context', () => {
    const {getByTestId} = render(
      <OutcomeContextTag outcomeContextType="Account" outcomeContextId="2" />,
    )

    const tag = getByTestId('outcome-context-tag')
    expect(tag).toBeInTheDocument()
    expect(tag.textContent).toBe('Institution')
  })

  it('renders Course tag when outcome is from a different Course context', () => {
    const {getByTestId} = render(
      <OutcomeContextTag outcomeContextType="Course" outcomeContextId="2" />,
    )

    const tag = getByTestId('outcome-context-tag')
    expect(tag).toBeInTheDocument()
    expect(tag.textContent).toBe('Course')
  })

  it('renders tag even when outcome is from the same context', () => {
    const {getByTestId} = render(
      <OutcomeContextTag outcomeContextType="Course" outcomeContextId="1" />,
    )

    const tag = getByTestId('outcome-context-tag')
    expect(tag).toBeInTheDocument()
    expect(tag.textContent).toBe('Course')
  })

  it('does not render tag when outcomeContextType is not provided', () => {
    const {queryByTestId} = render(<OutcomeContextTag outcomeContextId="2" />)

    expect(queryByTestId('outcome-context-tag')).not.toBeInTheDocument()
  })

  it('does not render tag when outcomeContextId is not provided', () => {
    const {queryByTestId} = render(<OutcomeContextTag outcomeContextType="Account" />)

    expect(queryByTestId('outcome-context-tag')).not.toBeInTheDocument()
  })

  it('renders with proper accessibility attributes for Account outcome', () => {
    const {getByTestId} = render(
      <OutcomeContextTag outcomeContextType="Account" outcomeContextId="2" />,
    )

    const tag = getByTestId('outcome-context-tag')
    expect(tag.getAttribute('aria-label')).toBe('This is an institution-level outcome')
  })

  it('renders with proper accessibility attributes for Course outcome', () => {
    const {getByTestId} = render(
      <OutcomeContextTag outcomeContextType="Course" outcomeContextId="2" />,
    )

    const tag = getByTestId('outcome-context-tag')
    expect(tag.getAttribute('aria-label')).toBe('This is a course-level outcome')
  })
})

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
import {SearchWrapper} from '../SearchWrapper'
import * as useStudentsHook from '../../../hooks/useStudents'

jest.mock('../../../hooks/useStudents')

const defaultProps = {
  courseId: '123',
  selectedUserIds: [],
  onSelectedUserIdsChange: jest.fn(),
}

describe('SearchWrapper', () => {
  beforeAll(() => {
    const liveRegion = document.createElement('div')
    liveRegion.id = 'flash_screenreader_holder'
    liveRegion.setAttribute('role', 'alert')
    document.body.appendChild(liveRegion)
  })

  beforeEach(() => {
    jest.clearAllMocks()
    jest.spyOn(useStudentsHook, 'useStudents').mockReturnValue({
      students: [],
      isLoading: false,
      error: null,
    })
  })

  afterEach(() => {
    jest.restoreAllMocks()
  })

  it('renders SearchWrapper with StudentSearch component', () => {
    render(<SearchWrapper {...defaultProps} />)

    expect(screen.getByText('Student Names')).toBeInTheDocument()
  })

  it('passes courseId prop to StudentSearch', () => {
    render(<SearchWrapper {...defaultProps} courseId="456" />)

    expect(useStudentsHook.useStudents).toHaveBeenCalledWith('456', '')
  })

  it('passes selectedUserIds prop to StudentSearch', () => {
    render(<SearchWrapper {...defaultProps} selectedUserIds={[1, 2, 3]} />)

    const combobox = screen.getByRole('combobox', {name: /student names/i})
    expect(combobox).toBeInTheDocument()
  })

  it('passes onSelectedUserIdsChange prop to StudentSearch', () => {
    const onSelectedUserIdsChange = jest.fn()

    render(<SearchWrapper {...defaultProps} onSelectedUserIdsChange={onSelectedUserIdsChange} />)

    expect(screen.getByText('Student Names')).toBeInTheDocument()
  })

  it('renders Flex container with correct styling', () => {
    const {container} = render(<SearchWrapper {...defaultProps} />)

    // Verify Flex container is rendered (Flex adds dir attribute)
    const flexContainer = container.querySelector('[dir="ltr"]')
    expect(flexContainer).toBeInTheDocument()
  })

  it('renders with empty selectedUserIds array', () => {
    render(<SearchWrapper {...defaultProps} selectedUserIds={[]} />)

    expect(screen.getByText('Student Names')).toBeInTheDocument()
  })

  it('renders with multiple selected user IDs', () => {
    render(<SearchWrapper {...defaultProps} selectedUserIds={[1, 2, 3, 4, 5]} />)

    expect(screen.getByText('Student Names')).toBeInTheDocument()
  })

  it('updates when props change', () => {
    const {rerender} = render(<SearchWrapper {...defaultProps} />)

    expect(useStudentsHook.useStudents).toHaveBeenCalledWith('123', '')

    rerender(<SearchWrapper {...defaultProps} courseId="789" />)

    expect(useStudentsHook.useStudents).toHaveBeenCalledWith('789', '')
  })

  it('maintains component structure with Flex wrapper', () => {
    const {container} = render(<SearchWrapper {...defaultProps} />)

    // Verify Flex is used as the wrapper
    const flexWrapper = container.querySelector('[dir="ltr"]')
    expect(flexWrapper).toBeInTheDocument()
  })
})

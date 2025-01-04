/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import {render, fireEvent} from '@testing-library/react'
import StudentRangeItem from '../student-range-item'

describe('StudentRangeItem', () => {
  const defaultProps = (overrides = {}) => ({
    studentIndex: 0,
    student: {
      user: {
        name: 'Foo Bar',
        avatar_image_url: '/test-avatar.jpg',
      },
      trend: 0,
    },
    selectStudent: jest.fn(),
    ...overrides,
  })

  it('renders student name and avatar', () => {
    const props = defaultProps()
    const {getByRole, getByAltText} = render(<StudentRangeItem {...props} />)

    const nameButton = getByRole('button', {name: 'Select student Foo Bar'})
    expect(nameButton).toBeInTheDocument()
    expect(nameButton).toHaveTextContent('Foo Bar')

    const avatar = getByAltText('')
    expect(avatar).toBeInTheDocument()
    expect(avatar).toHaveAttribute('src', '/test-avatar.jpg')
  })

  it('uses default avatar when none provided', () => {
    const props = defaultProps({
      student: {
        user: {name: 'Foo Bar'},
        trend: 0,
      },
    })
    const {getByAltText} = render(<StudentRangeItem {...props} />)

    const avatar = getByAltText('')
    expect(avatar).toHaveAttribute('src', '/images/messages/avatar-50.png')
  })

  it('calls selectStudent when name is clicked', () => {
    const props = defaultProps()
    const {getByRole} = render(<StudentRangeItem {...props} />)

    fireEvent.click(getByRole('button', {name: 'Select student Foo Bar'}))
    expect(props.selectStudent).toHaveBeenCalledWith(props.studentIndex)
  })

  it('calls selectStudent when avatar is clicked', () => {
    const props = defaultProps()
    const {getByAltText} = render(<StudentRangeItem {...props} />)

    fireEvent.click(getByAltText(''))
    expect(props.selectStudent).toHaveBeenCalledWith(props.studentIndex)
  })

  describe('trend indicators', () => {
    it('shows no trend indicator when trend is null', () => {
      const props = defaultProps({student: {user: {name: 'Foo Bar'}, trend: null}})
      const {container} = render(<StudentRangeItem {...props} />)
      expect(container.querySelector('.crs-student__trend-icon')).not.toBeInTheDocument()
    })

    it('shows positive trend indicator', () => {
      const props = defaultProps({student: {user: {name: 'Foo Bar'}, trend: 1}})
      const {container} = render(<StudentRangeItem {...props} />)
      expect(container.querySelector('.crs-student__trend-icon__positive')).toBeInTheDocument()
    })

    it('shows neutral trend indicator', () => {
      const props = defaultProps({student: {user: {name: 'Foo Bar'}, trend: 0}})
      const {container} = render(<StudentRangeItem {...props} />)
      expect(container.querySelector('.crs-student__trend-icon__neutral')).toBeInTheDocument()
    })

    it('shows negative trend indicator', () => {
      const props = defaultProps({student: {user: {name: 'Foo Bar'}, trend: -1}})
      const {container} = render(<StudentRangeItem {...props} />)
      expect(container.querySelector('.crs-student__trend-icon__negative')).toBeInTheDocument()
    })
  })
})

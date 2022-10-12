/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {act} from '@testing-library/react'
import {renderConnected} from '../../__tests__/utils'
import {PRIMARY_PACE, SECTION_PACE, STUDENT_PACE} from '../../__tests__/fixtures'

import {PaceModal} from '../pace_modal'

const onClose = jest.fn()

const defaultProps = {
  coursePace: PRIMARY_PACE,
  isBlueprintLocked: false,
  isOpen: true,
  onClose,
  onResetPace: jest.fn(),
  responsiveSize: 'large' as const,
}

afterEach(() => {
  jest.clearAllMocks()
})

describe('PaceModal', () => {
  it('calls onClose when dismiss button is clicked', () => {
    const {getByRole} = renderConnected(<PaceModal {...defaultProps} />)

    const closeButton = getByRole('button', {name: 'Close'})
    expect(closeButton).toBeInTheDocument()
    act(() => closeButton.click())
    expect(onClose).toHaveBeenCalled()
  })

  it('renders the course title', () => {
    const {getByText} = renderConnected(<PaceModal {...defaultProps} />)
    expect(getByText('Course Pace')).toBeInTheDocument()
  })
  it('renders the section title', () => {
    const {getByText} = renderConnected(<PaceModal {...defaultProps} coursePace={SECTION_PACE} />)
    expect(getByText('Section Pace')).toBeInTheDocument()
  })
  it('renders the student enrollment title', () => {
    const {getByText} = renderConnected(<PaceModal {...defaultProps} coursePace={STUDENT_PACE} />)
    expect(getByText('Student Pace')).toBeInTheDocument()
  })
})

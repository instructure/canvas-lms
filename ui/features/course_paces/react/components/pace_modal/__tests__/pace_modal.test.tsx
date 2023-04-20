// @ts-nocheck
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
import {renderConnected} from '../../../__tests__/utils'
import {
  PACE_CONTEXTS_SECTIONS_RESPONSE,
  PRIMARY_PACE,
  SECTION_1,
  SECTION_PACE,
  STUDENT_PACE,
} from '../../../__tests__/fixtures'

import {PaceModal} from '..'

const onClose = jest.fn(),
  clearCategoryError = jest.fn()

const defaultProps = {
  coursePace: PRIMARY_PACE,
  isOpen: true,
  onClose,
  clearCategoryError,
  onResetPace: jest.fn(),
  responsiveSize: 'large' as const,
  unappliedChangesExist: false,
  paceName: 'Custom Pace',
  selectedPaceContext: PACE_CONTEXTS_SECTIONS_RESPONSE.pace_contexts[0],
  enrolledSection: SECTION_1,
  assignmentsCount: 5,
  paceDuration: {weeks: 2, days: 3},
  plannedEndDate: '2022-12-01',
  compression: 0,
  compressDates: jest.fn(),
  uncompressDates: jest.fn(),
  setOuterResponsiveSize: jest.fn(),
}

afterEach(() => {
  jest.clearAllMocks()
})

describe('PaceModal', () => {
  it('calls onClose and clears publishing errors when dismiss button is clicked', () => {
    const {getByTestId} = renderConnected(<PaceModal {...defaultProps} />)
    const closeButton = getByTestId('course-pace-edit-close-x')
    expect(closeButton).toBeInTheDocument()
    act(() => closeButton.click())
    expect(onClose).toHaveBeenCalled()
    expect(clearCategoryError).toHaveBeenCalled()
  })

  it('renders the course title', () => {
    const {getByText} = renderConnected(<PaceModal {...defaultProps} />)
    expect(getByText('Course Pace: Custom Pace')).toBeInTheDocument()
  })
  it('renders the section title', () => {
    const {getByText} = renderConnected(<PaceModal {...defaultProps} coursePace={SECTION_PACE} />)
    expect(getByText('Section Pace: Custom Pace')).toBeInTheDocument()
  })
  it('renders the student enrollment title', () => {
    const {getByText} = renderConnected(<PaceModal {...defaultProps} coursePace={STUDENT_PACE} />)
    expect(getByText('Student Pace: Custom Pace')).toBeInTheDocument()
  })
})

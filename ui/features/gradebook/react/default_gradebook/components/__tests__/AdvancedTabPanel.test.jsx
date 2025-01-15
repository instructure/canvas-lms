/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import userEvent from '@testing-library/user-event'
import AdvancedTabPanel from '../AdvancedTabPanel'

describe('GradebookSettingsModal AdvancedTabPanel', () => {
  const defaultProps = {
    courseSettings: {
      allowFinalGradeOverride: false,
    },
    onCourseSettingsChange: jest.fn(),
  }

  beforeEach(() => {
    defaultProps.onCourseSettingsChange.mockClear()
  })

  const renderComponent = (props = {}) => {
    return render(<AdvancedTabPanel {...defaultProps} {...props} />)
  }

  describe('Allow final grade override option', () => {
    describe('when "allow final grade override" is enabled', () => {
      it('is checked', () => {
        const {getByLabelText} = renderComponent({
          courseSettings: {allowFinalGradeOverride: true},
        })
        const checkbox = getByLabelText('Allow final grade override')
        expect(checkbox).toBeChecked()
      })

      it('calls onCourseSettingsChange when changed', async () => {
        const {getByLabelText} = renderComponent({
          courseSettings: {allowFinalGradeOverride: true},
        })
        const checkbox = getByLabelText('Allow final grade override')
        await userEvent.click(checkbox)
        expect(defaultProps.onCourseSettingsChange).toHaveBeenCalledTimes(1)
        expect(defaultProps.onCourseSettingsChange).toHaveBeenCalledWith({
          allowFinalGradeOverride: false,
        })
      })
    })

    describe('when "allow final grade override" is disabled', () => {
      it('is unchecked', () => {
        const {getByLabelText} = renderComponent({
          courseSettings: {allowFinalGradeOverride: false},
        })
        const checkbox = getByLabelText('Allow final grade override')
        expect(checkbox).not.toBeChecked()
      })

      it('calls onCourseSettingsChange when changed', async () => {
        const {getByLabelText} = renderComponent({
          courseSettings: {allowFinalGradeOverride: false},
        })
        const checkbox = getByLabelText('Allow final grade override')
        await userEvent.click(checkbox)
        expect(defaultProps.onCourseSettingsChange).toHaveBeenCalledTimes(1)
        expect(defaultProps.onCourseSettingsChange).toHaveBeenCalledWith({
          allowFinalGradeOverride: true,
        })
      })
    })
  })
})

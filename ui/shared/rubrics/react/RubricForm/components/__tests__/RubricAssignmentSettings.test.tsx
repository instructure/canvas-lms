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
import userEvent from '@testing-library/user-event'
import {RubricAssignmentSettings} from '../RubricAssignmentSettings'

describe('RubricAssignmentSettings', () => {
  const defaultProps = {
    hideOutcomeResults: false,
    hidePoints: false,
    useForGrading: false,
    hideScoreTotal: false,
    canUseForGrading: true,
    setRubricFormField: vi.fn(),
  }

  afterEach(() => {
    vi.clearAllMocks()
  })

  describe('canUseForGrading prop', () => {
    it('renders "Use this rubric for assignment grading" checkbox when canUseForGrading is true', () => {
      render(<RubricAssignmentSettings {...defaultProps} canUseForGrading={true} />)

      expect(screen.getByTestId('use-for-grading-checkbox')).toBeInTheDocument()
    })

    it('does not render "Use this rubric for assignment grading" checkbox when canUseForGrading is false', () => {
      render(<RubricAssignmentSettings {...defaultProps} canUseForGrading={false} />)

      expect(screen.queryByTestId('use-for-grading-checkbox')).not.toBeInTheDocument()
    })

    it('still renders "Hide rubric score total from students" checkbox when canUseForGrading is false and useForGrading is false', () => {
      render(
        <RubricAssignmentSettings
          {...defaultProps}
          canUseForGrading={false}
          useForGrading={false}
        />,
      )

      expect(screen.getByTestId('hide-score-total-checkbox')).toBeInTheDocument()
    })

    it('does not render "Hide rubric score total from students" checkbox when useForGrading is true', () => {
      render(
        <RubricAssignmentSettings {...defaultProps} canUseForGrading={true} useForGrading={true} />,
      )

      expect(screen.queryByTestId('hide-score-total-checkbox')).not.toBeInTheDocument()
    })
  })

  describe('hidePoints prop', () => {
    it('does not render grading checkboxes when hidePoints is true', () => {
      render(<RubricAssignmentSettings {...defaultProps} hidePoints={true} />)

      expect(screen.queryByTestId('use-for-grading-checkbox')).not.toBeInTheDocument()
      expect(screen.queryByTestId('hide-score-total-checkbox')).not.toBeInTheDocument()
    })

    it('renders grading checkboxes when hidePoints is false', () => {
      render(<RubricAssignmentSettings {...defaultProps} hidePoints={false} />)

      expect(screen.getByTestId('use-for-grading-checkbox')).toBeInTheDocument()
    })
  })

  describe('checkbox interactions', () => {
    it('calls setRubricFormField when "Use this rubric for assignment grading" is checked', async () => {
      const setRubricFormField = vi.fn()
      render(<RubricAssignmentSettings {...defaultProps} setRubricFormField={setRubricFormField} />)

      const checkbox = screen.getByTestId('use-for-grading-checkbox')
      await userEvent.click(checkbox)

      expect(setRubricFormField).toHaveBeenCalledWith('useForGrading', true)
      expect(setRubricFormField).toHaveBeenCalledWith('hideScoreTotal', false)
    })

    it('calls setRubricFormField when "Hide rubric score total from students" is checked', async () => {
      const setRubricFormField = vi.fn()
      render(
        <RubricAssignmentSettings
          {...defaultProps}
          useForGrading={false}
          setRubricFormField={setRubricFormField}
        />,
      )

      const checkbox = screen.getByTestId('hide-score-total-checkbox')
      await userEvent.click(checkbox)

      expect(setRubricFormField).toHaveBeenCalledWith('hideScoreTotal', true)
    })

    it('calls setRubricFormField when "Don\'t post to Learning Mastery Gradebook" is checked', async () => {
      const setRubricFormField = vi.fn()
      render(<RubricAssignmentSettings {...defaultProps} setRubricFormField={setRubricFormField} />)

      const checkbox = screen.getByTestId('hide-outcome-results-checkbox')
      await userEvent.click(checkbox)

      expect(setRubricFormField).toHaveBeenCalledWith('hideOutcomeResults', true)
    })
  })

  describe('checkbox states', () => {
    it('reflects the checked state of "Use this rubric for assignment grading"', () => {
      const {rerender} = render(
        <RubricAssignmentSettings {...defaultProps} useForGrading={false} />,
      )

      let checkbox = screen.getByTestId('use-for-grading-checkbox')
      expect(checkbox).not.toBeChecked()

      rerender(<RubricAssignmentSettings {...defaultProps} useForGrading={true} />)
      checkbox = screen.getByTestId('use-for-grading-checkbox')
      expect(checkbox).toBeChecked()
    })

    it('reflects the checked state of "Hide rubric score total from students"', () => {
      const {rerender} = render(
        <RubricAssignmentSettings {...defaultProps} useForGrading={false} hideScoreTotal={false} />,
      )

      let checkbox = screen.getByTestId('hide-score-total-checkbox')
      expect(checkbox).not.toBeChecked()

      rerender(
        <RubricAssignmentSettings {...defaultProps} useForGrading={false} hideScoreTotal={true} />,
      )
      checkbox = screen.getByTestId('hide-score-total-checkbox')
      expect(checkbox).toBeChecked()
    })

    it('reflects the checked state of "Don\'t post to Learning Mastery Gradebook"', () => {
      const {rerender} = render(
        <RubricAssignmentSettings {...defaultProps} hideOutcomeResults={false} />,
      )

      let checkbox = screen.getByTestId('hide-outcome-results-checkbox')
      expect(checkbox).not.toBeChecked()

      rerender(<RubricAssignmentSettings {...defaultProps} hideOutcomeResults={true} />)
      checkbox = screen.getByTestId('hide-outcome-results-checkbox')
      expect(checkbox).toBeChecked()
    })
  })
})

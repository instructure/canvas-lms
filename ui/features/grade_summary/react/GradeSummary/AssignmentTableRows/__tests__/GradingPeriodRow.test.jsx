/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import fakeENV from '@canvas/test-utils/fakeENV'
import {Table} from '@instructure/ui-table'

import {gradingPeriodRow} from '../GradingPeriodRow'
import {GradingPeriod} from '../../../../graphql/GradingPeriod'
import {Assignment} from '../../../../graphql/Assignment'
import {AssignmentGroup} from '../../../../graphql/AssignmentGroup'
import {GradingStandard} from '../../../../graphql/GradingStandard'

const defaultGradingPeriod = GradingPeriod.mock()

const defaultQueryData = {
  gradingStandard: GradingStandard.mock(),
  assignmentGroupsConnection: {
    nodes: [AssignmentGroup.mock()],
  },
  applyGroupWeights: false,
}

const defaultAssignmentsData = {
  assignments: [
    Assignment.mock({
      gradingPeriodId: '1',
    }),
  ],
}

const defaultCourseLevelGrades = {
  score: 90,
  possible: 100,
}

const setup = (
  gradingPeriod = defaultGradingPeriod,
  queryData = defaultQueryData,
  assignmentsData = defaultAssignmentsData,
  calculateOnlyGradedAssignments = false,
  courseLevelGrades = defaultCourseLevelGrades,
  hideTotalRow = false,
) => {
  return render(
    <Table caption="Grading Period Row - Vitest Test Table">
      <Table.Body>
        {gradingPeriodRow(
          gradingPeriod,
          queryData,
          assignmentsData,
          calculateOnlyGradedAssignments,
          courseLevelGrades,
          hideTotalRow,
        )}
      </Table.Body>
    </Table>,
  )
}

describe('GradingPeriodRow', () => {
  beforeEach(() => {
    fakeENV.setup()
    ENV.restrict_quantitative_data = false
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  it('renders grading period title', () => {
    const {getByText} = setup()
    expect(getByText('Grading Period 1')).toBeInTheDocument()
  })

  describe('Grade display based on hideTotalRow and restrict_quantitative_data', () => {
    it('shows numeric score when hideTotalRow is false and restrict_quantitative_data is false', () => {
      ENV.restrict_quantitative_data = false
      const {getByText} = setup(
        defaultGradingPeriod,
        defaultQueryData,
        defaultAssignmentsData,
        false,
        defaultCourseLevelGrades,
        false,
      )
      expect(getByText('90.00/100.00')).toBeInTheDocument()
    })

    it('shows letter grade when hideTotalRow is false and restrict_quantitative_data is true', () => {
      ENV.restrict_quantitative_data = true
      const {getByText, queryByText} = setup(
        defaultGradingPeriod,
        defaultQueryData,
        defaultAssignmentsData,
        false,
        defaultCourseLevelGrades,
        false,
      )
      // Should show letter grade (A− for 90%)
      expect(getByText('A−')).toBeInTheDocument()
      // Should NOT show numeric score
      expect(queryByText('90.00/100.00')).not.toBeInTheDocument()
    })

    it('hides grade (shows icon) when hideTotalRow is true and restrict_quantitative_data is true', () => {
      ENV.restrict_quantitative_data = true
      const {queryByText, container} = setup(
        defaultGradingPeriod,
        defaultQueryData,
        defaultAssignmentsData,
        false,
        defaultCourseLevelGrades,
        true,
      )
      // THE BUG FIX: Should NOT show letter grade even when restrict_quantitative_data is true
      expect(queryByText('A−')).not.toBeInTheDocument()
      // Should NOT show numeric score
      expect(queryByText('90.00/100.00')).not.toBeInTheDocument()
      // Should NOT show percentage
      expect(queryByText('90.00%')).not.toBeInTheDocument()
      // Should show the IconOffLine component (indicates grade is hidden)
      expect(container.querySelector('svg[name="IconOff"]')).toBeInTheDocument()
    })

    it('hides grade (shows icon) when hideTotalRow is true and restrict_quantitative_data is false', () => {
      ENV.restrict_quantitative_data = false
      const {queryByText, container} = setup(
        defaultGradingPeriod,
        defaultQueryData,
        defaultAssignmentsData,
        false,
        defaultCourseLevelGrades,
        true,
      )
      // Should NOT show numeric score
      expect(queryByText('90.00/100.00')).not.toBeInTheDocument()
      // Should NOT show percentage (percentage cell should not render at all)
      expect(queryByText('90.00%')).not.toBeInTheDocument()
      // Should show ONE IconOffLine component (indicates grade is hidden)
      const icons = container.querySelectorAll('svg[name="IconOff"]')
      expect(icons).toHaveLength(1)
    })
  })
})

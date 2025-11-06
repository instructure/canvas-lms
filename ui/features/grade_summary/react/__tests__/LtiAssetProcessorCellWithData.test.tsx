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
import {queryClient} from '@canvas/query'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import {
  LtiAssetProcessorCellWithData,
  AssetProcessorHeaderForGrades,
} from '../LtiAssetProcessorCellWithData'
import {
  defaultGetCourseAssignmentsAssetReportsResult,
  emptyGetCourseAssignmentsAssetReportsResult,
} from '@canvas/lti-asset-processor/queries/__fixtures__/GetCourseAssignmentsAssetReports'

describe('LtiAssetProcessorCellWithData', () => {
  beforeEach(() => {
    queryClient.clear()
    window.ENV = {
      ...window.ENV,
      FEATURES: {
        ...window.ENV?.FEATURES,
        lti_asset_processor: true,
      },
    }
  })

  it('renders LtiAssetProcessorCell when data is available for the assignment', () => {
    const mockData = defaultGetCourseAssignmentsAssetReportsResult({assignmentId: 'assignment_1'})

    // Set query data for infinite query - it expects pages array
    queryClient.setQueryData(['course_assignments_asset_reports', 'course_1', null, 'student_1'], {
      pages: [mockData],
      pageParams: [undefined],
    })

    render(
      <MockedQueryProvider>
        <LtiAssetProcessorCellWithData
          assignmentId="assignment_1"
          courseId="course_1"
          studentId="student_1"
          gradingPeriodId={null}
        />
      </MockedQueryProvider>,
    )

    expect(screen.getByText('All good')).toBeInTheDocument()
  })

  it('renders null when no data is available for the assignment', () => {
    const mockData = defaultGetCourseAssignmentsAssetReportsResult({
      assignmentId: 'different_assignment',
    })

    queryClient.setQueryData(['course_assignments_asset_reports', 'course_1', null, 'student_1'], {
      pages: [mockData],
      pageParams: [undefined],
    })

    const {container} = render(
      <MockedQueryProvider>
        <LtiAssetProcessorCellWithData
          assignmentId="assignment_1"
          courseId="course_1"
          studentId="student_1"
          gradingPeriodId={null}
        />
      </MockedQueryProvider>,
    )

    expect(container.textContent).toBe('')
  })

  it('renders null when feature flag is disabled', () => {
    window.ENV = {
      ...window.ENV,
      FEATURES: {
        ...window.ENV?.FEATURES,
        lti_asset_processor: false,
      },
    }

    const {container} = render(
      <MockedQueryProvider>
        <LtiAssetProcessorCellWithData
          assignmentId="assignment_1"
          courseId="course_1"
          studentId="student_1"
          gradingPeriodId={null}
        />
      </MockedQueryProvider>,
    )

    expect(container.textContent).toBe('')
  })

  it('renders null while loading', () => {
    // No query data set, so query will be in loading state
    const {container} = render(
      <MockedQueryProvider>
        <LtiAssetProcessorCellWithData
          assignmentId="assignment_1"
          courseId="course_1"
          studentId="student_1"
          gradingPeriodId={null}
        />
      </MockedQueryProvider>,
    )

    expect(container.textContent).toBe('')
  })

  it('passes correct props to LtiAssetProcessorCell', () => {
    const mockData = defaultGetCourseAssignmentsAssetReportsResult({assignmentId: 'assignment_1'})

    queryClient.setQueryData(
      ['course_assignments_asset_reports', 'course_1', 'period_1', 'student_1'],
      {
        pages: [mockData],
        pageParams: [undefined],
      },
    )

    render(
      <MockedQueryProvider>
        <LtiAssetProcessorCellWithData
          assignmentId="assignment_1"
          courseId="course_1"
          studentId="student_1"
          gradingPeriodId="period_1"
        />
      </MockedQueryProvider>,
    )

    // The LtiAssetProcessorCell should receive the data from the hook
    expect(screen.getByText('All good')).toBeInTheDocument()
  })
})

describe('AssetProcessorHeaderForGrades', () => {
  beforeEach(() => {
    queryClient.clear()
    window.ENV = {
      ...window.ENV,
      FEATURES: {
        ...window.ENV?.FEATURES,
        lti_asset_processor: true,
      },
    }
  })

  it('renders header text when data is available', () => {
    const mockData = defaultGetCourseAssignmentsAssetReportsResult({assignmentId: 'assignment_1'})

    queryClient.setQueryData(['course_assignments_asset_reports', 'course_1', null, 'student_1'], {
      pages: [mockData],
      pageParams: [undefined],
    })

    render(
      <MockedQueryProvider>
        <AssetProcessorHeaderForGrades
          courseId="course_1"
          studentId="student_1"
          gradingPeriodId={null}
        />
      </MockedQueryProvider>,
    )

    expect(screen.getByText('Document Processors')).toBeInTheDocument()
  })

  it('renders null when no data is available', () => {
    const emptyResponse = emptyGetCourseAssignmentsAssetReportsResult()

    queryClient.setQueryData(['course_assignments_asset_reports', 'course_1', null, 'student_1'], {
      pages: [emptyResponse],
      pageParams: [undefined],
    })

    const {container} = render(
      <MockedQueryProvider>
        <AssetProcessorHeaderForGrades
          courseId="course_1"
          studentId="student_1"
          gradingPeriodId={null}
        />
      </MockedQueryProvider>,
    )

    expect(container.textContent).toBe('')
  })

  it('renders null when feature flag is disabled', () => {
    window.ENV = {
      ...window.ENV,
      FEATURES: {
        ...window.ENV?.FEATURES,
        lti_asset_processor: false,
      },
    }

    const {container} = render(
      <MockedQueryProvider>
        <AssetProcessorHeaderForGrades
          courseId="course_1"
          studentId="student_1"
          gradingPeriodId={null}
        />
      </MockedQueryProvider>,
    )

    expect(container.textContent).toBe('')
  })

  it('renders null while loading', () => {
    // No query data set, so query will be in loading state
    const {container} = render(
      <MockedQueryProvider>
        <AssetProcessorHeaderForGrades
          courseId="course_1"
          studentId="student_1"
          gradingPeriodId={null}
        />
      </MockedQueryProvider>,
    )

    expect(container.textContent).toBe('')
  })
})

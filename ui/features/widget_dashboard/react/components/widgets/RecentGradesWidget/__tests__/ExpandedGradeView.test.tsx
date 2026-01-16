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
import {ExpandedGradeView} from '../ExpandedGradeView'
import type {RecentGradeSubmission} from '../../../../types'
import {WidgetDashboardProvider} from '../../../../hooks/useWidgetDashboardContext'

const mockSubmission: RecentGradeSubmission = {
  _id: 'sub1',
  score: 85,
  grade: 'B',
  submittedAt: '2025-11-28T10:00:00Z',
  gradedAt: '2025-11-30T14:30:00Z',
  state: 'graded',
  assignment: {
    _id: '101',
    name: 'Test Assignment',
    htmlUrl: '/courses/1/assignments/101',
    pointsPossible: 100,
    submissionTypes: ['online_text_entry'],
    quiz: null,
    discussion: null,
    course: {
      _id: '1',
      name: 'Test Course',
      courseCode: 'TEST-101',
    },
  },
}

const mockSharedCourseData = [
  {
    courseId: '1',
    courseCode: 'TEST-101',
    courseName: 'Test Course',
    currentGrade: 88,
    gradingScheme: 'percentage' as const,
    lastUpdated: '2025-11-30T14:30:00Z',
  },
]

const renderWithContext = (component: React.ReactElement) => {
  return render(
    <WidgetDashboardProvider sharedCourseData={mockSharedCourseData}>
      {component}
    </WidgetDashboardProvider>,
  )
}

describe('ExpandedGradeView', () => {
  it('renders the expanded view', () => {
    renderWithContext(<ExpandedGradeView submission={mockSubmission} />)
    expect(screen.getByTestId('expanded-grade-view-sub1')).toBeInTheDocument()
  })

  it('renders the grade display with assignment grade', () => {
    renderWithContext(<ExpandedGradeView submission={mockSubmission} />)
    expect(screen.getByTestId('grade-display-sub1')).toBeInTheDocument()
    expect(screen.getByTestId('grade-percentage-sub1')).toHaveTextContent('B')
  })

  it('displays course grade from shared course data', () => {
    renderWithContext(<ExpandedGradeView submission={mockSubmission} />)
    expect(screen.getByTestId('course-grade-label-sub1')).toHaveTextContent('Course grade: 88%')
  })

  it('renders the rubric section with placeholder', () => {
    renderWithContext(<ExpandedGradeView submission={mockSubmission} />)
    expect(screen.getByTestId('rubric-section-heading-sub1')).toHaveTextContent('Rubric')
    expect(screen.getByTestId('rubric-placeholder-sub1')).toHaveTextContent(
      'Rubric details will be displayed here',
    )
  })

  it('renders the feedback section with placeholder', () => {
    renderWithContext(<ExpandedGradeView submission={mockSubmission} />)
    expect(screen.getByTestId('feedback-section-heading-sub1')).toHaveTextContent('Feedback')
    expect(screen.getByTestId('feedback-placeholder-sub1')).toHaveTextContent(
      'Feedback comments will be displayed here',
    )
  })

  it('renders the view inline feedback button', () => {
    renderWithContext(<ExpandedGradeView submission={mockSubmission} />)
    expect(screen.getByTestId('view-inline-feedback-button-sub1')).toHaveTextContent(
      'View inline feedback',
    )
  })

  it('renders the open assignment link', () => {
    renderWithContext(<ExpandedGradeView submission={mockSubmission} />)
    const link = screen.getByTestId('open-assignment-link-sub1')
    expect(link).toHaveTextContent('Open assignment')
    expect(link).toHaveAttribute('href', '/courses/1/assignments/101')
  })

  it('renders the open what-if grading tool link', () => {
    renderWithContext(<ExpandedGradeView submission={mockSubmission} />)
    const link = screen.getByTestId('open-whatif-link-sub1')
    expect(link).toHaveTextContent('Open what-if grading tool')
    expect(link).toHaveAttribute('href', '/courses/1/grades')
  })

  it('renders the message instructor link', () => {
    renderWithContext(<ExpandedGradeView submission={mockSubmission} />)
    const link = screen.getByTestId('message-instructor-link-sub1')
    expect(link).toHaveTextContent('Message instructor')
    expect(link).toHaveAttribute('href', '/conversations?context_id=course_1')
  })

  it('displays course grade when no course data available', () => {
    render(
      <WidgetDashboardProvider sharedCourseData={[]}>
        <ExpandedGradeView submission={mockSubmission} />
      </WidgetDashboardProvider>,
    )
    expect(screen.getByTestId('course-grade-label-sub1')).toHaveTextContent('Course grade: N/A')
  })
})

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
import {render, screen} from '@testing-library/react'
import MetricsList from '../MetricsList'

describe('MetricsList', () => {
  const defaultProps = {
    analytics: {
      tardiness_breakdown: {
        missing: 0,
        late: 0,
      },
    },
  }

  describe('grade', () => {
    it('shows no grade when no enrollments exist', () => {
      render(<MetricsList {...defaultProps} />)
      expect(screen.queryByText('Grade')).not.toBeInTheDocument()
    })

    it('shows override_grade if present and final_grade_override is true', () => {
      const overrideGrade = 'A+'
      render(
        <MetricsList
          {...defaultProps}
          user={{
            enrollments: [
              {
                grades: {
                  override_grade: overrideGrade,
                },
              },
            ],
          }}
          allowFinalGradeOverride={true}
        />,
      )
      expect(screen.getByText('Grade')).toBeInTheDocument()
      expect(screen.getByText(overrideGrade)).toBeInTheDocument()
    })

    it('shows current_grade if override_grade is present and final_grade_override is false', () => {
      const currentGrade = 'B'
      render(
        <MetricsList
          {...defaultProps}
          user={{
            enrollments: [
              {
                grades: {
                  override_grade: 'A+',
                  current_grade: currentGrade,
                },
              },
            ],
          }}
          allowFinalGradeOverride={false}
        />,
      )
      expect(screen.getByText('Grade')).toBeInTheDocument()
      expect(screen.getByText(currentGrade)).toBeInTheDocument()
    })

    it('shows override_score if present and override_grade is not present', () => {
      const overrideScore = 85
      render(
        <MetricsList
          {...defaultProps}
          user={{
            enrollments: [
              {
                grades: {
                  override_score: overrideScore,
                },
              },
            ],
          }}
          allowFinalGradeOverride={true}
        />,
      )
      expect(screen.getByText('Grade')).toBeInTheDocument()
      expect(screen.getByText(`${overrideScore}%`)).toBeInTheDocument()
    })

    it('shows current_grade if present and override fields are not present', () => {
      const currentGrade = 'B+'
      render(
        <MetricsList
          {...defaultProps}
          user={{
            enrollments: [
              {
                grades: {
                  current_grade: currentGrade,
                },
              },
            ],
          }}
        />,
      )
      expect(screen.getByText('Grade')).toBeInTheDocument()
      expect(screen.getByText(currentGrade)).toBeInTheDocument()
    })

    it('shows current_score by default', () => {
      const currentScore = 88
      render(
        <MetricsList
          {...defaultProps}
          user={{
            enrollments: [
              {
                grades: {
                  current_score: currentScore,
                },
              },
            ],
          }}
        />,
      )
      expect(screen.getByText('Grade')).toBeInTheDocument()
      expect(screen.getByText(`${currentScore}%`)).toBeInTheDocument()
    })

    it('shows - if the enrollment is undefined', () => {
      render(
        <MetricsList
          {...defaultProps}
          user={{
            enrollments: undefined,
          }}
        />,
      )
      expect(screen.queryByText('Grade')).not.toBeInTheDocument()
    })
  })

  describe('missing assignments', () => {
    it('shows count from analytics data when present', () => {
      const missingCount = 3
      render(
        <MetricsList
          {...defaultProps}
          analytics={{
            tardiness_breakdown: {
              missing: missingCount,
            },
          }}
          user={{
            enrollments: [
              {
                grades: {},
              },
            ],
          }}
        />,
      )
      expect(screen.getByText('Missing')).toBeInTheDocument()
      expect(screen.getByText(missingCount.toString())).toBeInTheDocument()
    })
  })

  describe('late assignments', () => {
    it('shows value from analytics when present', () => {
      const lateCount = 5
      render(
        <MetricsList
          {...defaultProps}
          analytics={{
            tardiness_breakdown: {
              late: lateCount,
            },
          }}
          user={{
            enrollments: [
              {
                grades: {},
              },
            ],
          }}
        />,
      )
      expect(screen.getByText('Late')).toBeInTheDocument()
      expect(screen.getByText(lateCount.toString())).toBeInTheDocument()
    })
  })
})

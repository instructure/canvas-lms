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
import timezone from 'timezone'
import tzInTest from '@instructure/moment-utils/specHelpers'
import newYork from 'timezone/America/New_York'
import AssessmentSummary from '../AssessmentSummary'
import {overallAnonymityStates} from '../../AuditTrailHelpers'
import {getI18nFormats} from '@canvas/datetime/configureDateTime'

const {FULL, NA, PARTIAL} = overallAnonymityStates

describe('AssessmentSummary', () => {
  let defaultProps

  beforeEach(() => {
    tzInTest.configureAndRestoreLater({
      tz: timezone(newYork, 'America/New_York'),
      tzData: {
        'America/New_York': newYork,
      },
      formats: getI18nFormats(),
    })

    defaultProps = {
      anonymityDate: new Date('2015-04-04T19:00:00.000Z'),
      assignment: {
        gradesPublishedAt: '2015-05-04T16:00:00.000Z',
        pointsPossible: 10,
      },
      finalGradeDate: new Date('2015-04-18T17:00:00.000Z'),
      overallAnonymity: FULL,
      submission: {
        score: 9.5,
      },
    }
  })

  afterEach(() => {
    tzInTest.restore()
  })

  describe('Final Grade', () => {
    it('shows the score out of points possible', () => {
      render(<AssessmentSummary {...defaultProps} />)
      expect(screen.getByText(/9\.5\/10/)).toBeInTheDocument()
    })

    it('rounds the score to two decimal places', () => {
      const props = {
        ...defaultProps,
        submission: {score: 9.523},
      }
      render(<AssessmentSummary {...props} />)
      expect(screen.getByText(/9\.52\/10/)).toBeInTheDocument()
    })

    it('rounds the points possible to two decimal places', () => {
      const props = {
        ...defaultProps,
        assignment: {...defaultProps.assignment, pointsPossible: 10.017},
      }
      render(<AssessmentSummary {...props} />)
      expect(screen.getByText(/9\.5\/10\.02/)).toBeInTheDocument()
    })

    it('displays zero out of points possible when the score is zero', () => {
      const props = {
        ...defaultProps,
        submission: {score: 0},
      }
      render(<AssessmentSummary {...props} />)
      expect(screen.getByText(/0\/10/)).toBeInTheDocument()
    })

    it('displays score out of zero points possible when the assignment is worth zero points', () => {
      const props = {
        ...defaultProps,
        assignment: {...defaultProps.assignment, pointsPossible: 0},
      }
      render(<AssessmentSummary {...props} />)
      expect(screen.getByText(/9\.5\/0/)).toBeInTheDocument()
    })

    it('displays "–" (en dash) for score when the submission is ungraded', () => {
      const props = {
        ...defaultProps,
        submission: {score: null},
      }
      render(<AssessmentSummary {...props} />)
      expect(screen.getByText(/–\/10/)).toBeInTheDocument()
    })

    it('displays the "final grade" date from the audit trail', () => {
      render(<AssessmentSummary {...defaultProps} />)
      const dateElement = screen.getByTestId('final-grade-date')
      expect(dateElement).toHaveAttribute('datetime', '2015-04-18T17:00:00.000Z')
    })

    it('includes the time on the visible date', () => {
      render(<AssessmentSummary {...defaultProps} />)
      const dateElement = screen.getByTestId('final-grade-date')
      expect(dateElement).toHaveTextContent(/1pm/)
    })
  })

  describe('Posted to student', () => {
    it('displays the "grades published" date from the assignment', () => {
      render(<AssessmentSummary {...defaultProps} />)
      const dateElement = screen.getByTestId('grades-posted-date')
      expect(dateElement).toHaveAttribute('datetime', defaultProps.assignment.gradesPublishedAt)
    })

    it('includes the time on the visible date', () => {
      render(<AssessmentSummary {...defaultProps} />)
      const dateElement = screen.getByTestId('grades-posted-date')
      expect(dateElement).toHaveTextContent(/12pm/)
    })
  })

  describe('Overall Anonymity', () => {
    describe('when anonymity was used without interruption', () => {
      beforeEach(() => {
        defaultProps.overallAnonymity = FULL
      })

      it('labels the indicator with "Anonymous On"', () => {
        render(<AssessmentSummary {...defaultProps} />)
        expect(screen.getByText('Anonymous On')).toBeInTheDocument()
      })

      it('displays the anonymity date', () => {
        render(<AssessmentSummary {...defaultProps} />)
        const dateElement = screen.getByTestId('anonymity-date')
        expect(dateElement).toHaveAttribute('datetime', '2015-04-04T19:00:00.000Z')
      })

      it('includes the time on the visible date', () => {
        render(<AssessmentSummary {...defaultProps} />)
        const dateElement = screen.getByTestId('anonymity-date')
        expect(dateElement).toHaveTextContent(/3pm/)
      })
    })

    describe('when anonymity was applied multiple times', () => {
      beforeEach(() => {
        defaultProps.overallAnonymity = PARTIAL
      })

      it('labels the indicator with "Partially Anonymous"', () => {
        render(<AssessmentSummary {...defaultProps} />)
        expect(screen.getByText('Partially Anonymous')).toBeInTheDocument()
      })

      it('displays the anonymity date', () => {
        render(<AssessmentSummary {...defaultProps} />)
        const dateElement = screen.getByTestId('anonymity-date')
        expect(dateElement).toHaveAttribute('datetime', '2015-04-04T19:00:00.000Z')
      })

      it('includes the time on the visible date', () => {
        render(<AssessmentSummary {...defaultProps} />)
        const dateElement = screen.getByTestId('anonymity-date')
        expect(dateElement).toHaveTextContent(/3pm/)
      })
    })

    describe('when anonymity was not used', () => {
      beforeEach(() => {
        defaultProps.anonymityDate = null
        defaultProps.overallAnonymity = NA
      })

      it('labels the indicator with "Anonymous Off"', () => {
        render(<AssessmentSummary {...defaultProps} />)
        expect(screen.getByText('Anonymous Off')).toBeInTheDocument()
      })

      it('displays "Anonymous was never turned on" message', () => {
        render(<AssessmentSummary {...defaultProps} />)
        expect(screen.getByText('Anonymous was never turned on')).toBeInTheDocument()
      })
    })
  })
})

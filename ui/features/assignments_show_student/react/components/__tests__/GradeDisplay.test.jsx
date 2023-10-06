/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import GradeDisplay from '../GradeDisplay'

describe('GradeDisplay', () => {
  describe('when gradingStatus is set to Excused', () => {
    it('renders the text "Excused"', () => {
      const {getByTestId} = render(
        <GradeDisplay gradingType="points" pointsPossible={10} gradingStatus="excused" />
      )
      expect(getByTestId('grade-display')).toHaveTextContent('Excused')
    })
  })

  describe('for a points-based assignment', () => {
    describe('when no grade has been awarded', () => {
      it('renders the number of possible points', () => {
        const {getByTestId} = render(<GradeDisplay pointsPossible={5} gradingType="points" />)
        expect(getByTestId('grade-display')).toHaveTextContent('5 Points Possible')
      })

      it('renders the number of possible points in decimal', () => {
        const {getByTestId} = render(<GradeDisplay pointsPossible={5.4} gradingType="points" />)
        expect(getByTestId('grade-display')).toHaveTextContent('5.4 Points Possible')
      })

      it('renders the number of possible points in decimal with rounding', () => {
        const {getByTestId} = render(<GradeDisplay pointsPossible={5.0001} gradingType="points" />)
        expect(getByTestId('grade-display')).toHaveTextContent('5 Points Possible')
      })

      it('renders a screenreader string including "Ungraded" and the number of points', () => {
        const {getByText} = render(<GradeDisplay pointsPossible={10} gradingType="points" />)
        expect(getByText('Ungraded, 10 Possible Points')).toBeInTheDocument()
      })

      it('renders a screenreader string including "Ungraded" and the number of points in decimal', () => {
        const {getByText} = render(<GradeDisplay pointsPossible={10.2} gradingType="points" />)
        expect(getByText('Ungraded, 10.2 Possible Points')).toBeInTheDocument()
      })

      it('renders "1 Possible Point" when possiblePoints is 1', () => {
        const {getByTestId} = render(<GradeDisplay pointsPossible={1} gradingType="points" />)
        expect(getByTestId('grade-display')).toHaveTextContent('1 Point Possible')
      })

      it('renders a screenreader string including "Ungraded" when possiblePoints is 1', () => {
        const {getByText} = render(<GradeDisplay pointsPossible={1} gradingType="points" />)
        expect(getByText('Ungraded, 1 Possible Point')).toBeInTheDocument()
      })

      it('does not indicate possible points if possiblePoints is null', () => {
        const {getByTestId, queryByText} = render(
          <GradeDisplay pointsPossible={null} gradingType="points" />
        )
        expect(getByTestId('grade-display')).toBeEmptyDOMElement()
        expect(queryByText(/Possible Point/)).not.toBeInTheDocument()
      })
    })

    describe('when a grade has been awarded', () => {
      it('renders the awarded score and the possible points', () => {
        const {getByTestId} = render(
          <GradeDisplay receivedGrade={2} pointsPossible={5} gradingType="points" />
        )
        expect(getByTestId('grade-display')).toHaveTextContent('2/5 Points')
      })

      it('renders the awarded score and the possible points in decimal', () => {
        const {getByTestId} = render(
          <GradeDisplay receivedGrade={2} pointsPossible={5.7} gradingType="points" />
        )
        expect(getByTestId('grade-display')).toHaveTextContent('2/5.7 Points')
      })

      it('renders the awarded score and the possible points when possiblePoints is 1', () => {
        const {getByTestId} = render(
          <GradeDisplay receivedGrade={1} pointsPossible={1} gradingType="points" />
        )
        expect(getByTestId('grade-display')).toHaveTextContent('1/1 Point')
      })
    })
  })

  describe('for a pass-fail assignment', () => {
    it('renders "Complete" when a "complete" grade has been awarded', () => {
      const {getByTestId} = render(
        <GradeDisplay receivedGrade="complete" pointsPossible={5} gradingType="pass_fail" />
      )
      expect(getByTestId('grade-display')).toHaveTextContent('complete')
    })

    it('renders "Incomplete" when an "incomplete" grade has been awarded', () => {
      const {getByTestId} = render(
        <GradeDisplay receivedGrade="incomplete" pointsPossible={5} gradingType="pass_fail" />
      )
      expect(getByTestId('grade-display')).toHaveTextContent('incomplete')
    })

    it('renders no text when no grade has been awarded', () => {
      const {getByTestId} = render(<GradeDisplay pointsPossible={5} gradingType="pass_fail" />)
      expect(getByTestId('grade-display')).toBeEmptyDOMElement()
    })

    it('renders "ungraded" as screen-reader content', () => {
      const {getByText} = render(<GradeDisplay pointsPossible={5} gradingType="pass_fail" />)
      expect(getByText('ungraded')).toBeInTheDocument()
    })
  })

  describe('for a percent-based assignment', () => {
    it('renders the grade as a percent when one has been awarded', () => {
      const {getByTestId} = render(
        <GradeDisplay receivedGrade="15%" pointsPossible={5} gradingType="percent" />
      )
      expect(getByTestId('grade-display')).toHaveTextContent('15%')
    })

    it('renders no text if no grade has been awarded', () => {
      const {getByTestId} = render(<GradeDisplay pointsPossible={5} gradingType="percent" />)
      expect(getByTestId('grade-display')).toBeEmptyDOMElement()
    })

    it('renders "ungraded" as screen-reader content', () => {
      const {getByText} = render(<GradeDisplay pointsPossible={5} gradingType="percent" />)
      expect(getByText('ungraded')).toBeInTheDocument()
    })
  })

  describe('for an assignment graded using a GPA scale', () => {
    it('renders the grade when one has been awarded', () => {
      const {getByTestId} = render(
        <GradeDisplay receivedGrade="just great" pointsPossible={5} gradingType="gpa_scale" />
      )
      expect(getByTestId('grade-display')).toHaveTextContent('just great')
    })

    it('renders no text if no grade has been awarded', () => {
      const {getByTestId} = render(<GradeDisplay pointsPossible={5} gradingType="gpa_scale" />)
      expect(getByTestId('grade-display')).toBeEmptyDOMElement()
    })

    it('renders "ungraded" as screen-reader content', () => {
      const {getByText} = render(<GradeDisplay pointsPossible={5} gradingType="gpa_scale" />)
      expect(getByText('ungraded')).toBeInTheDocument()
    })
  })

  describe('for an assignment graded using a letter grade', () => {
    it('renders the grade when one has been awarded', () => {
      const {getByTestId} = render(
        <GradeDisplay receivedGrade="A-" pointsPossible={5} gradingType="letter_grade" />
      )
      expect(getByTestId('grade-display')).toHaveTextContent('A−')
    })

    it('renders no displayed text if no grade has been awarded', () => {
      const {getByTestId} = render(<GradeDisplay pointsPossible={5} gradingType="letter_grade" />)
      expect(getByTestId('grade-display')).toBeEmptyDOMElement()
    })

    it('renders "ungraded" as screen-reader content', () => {
      const {getByText} = render(<GradeDisplay pointsPossible={5} gradingType="letter_grade" />)
      expect(getByText('ungraded')).toBeInTheDocument()
    })
  })
})

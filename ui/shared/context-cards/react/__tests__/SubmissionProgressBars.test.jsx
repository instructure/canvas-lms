/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import SubmissionProgressBars from '../SubmissionProgressBars'

const user = {_id: '1'}

describe('SubmissionProgressBars', () => {
  describe('displayGrade', () => {
    it('returns EX when submission is excused', () => {
      const submission = {id: '1', excused: true, assignment: {points_possible: 25}}
      expect(SubmissionProgressBars.displayGrade(submission)).toBe('EX')
    })

    it('returns the grade when it is a percentage', () => {
      const percentage = '80%'
      const submission = {
        id: '1',
        excused: false,
        grade: percentage,
        assignment: {points_possible: 25},
      }
      expect(SubmissionProgressBars.displayGrade(submission)).toBe(percentage)
    })

    it('calls renderIcon when grade is complete or incomplete', () => {
      const submission = {
        id: '1',
        excused: false,
        assignment: {points_possible: 25},
      }
      const spy = jest.spyOn(SubmissionProgressBars, 'renderIcon')

      SubmissionProgressBars.displayGrade({...submission, grade: 'complete'})
      expect(spy).toHaveBeenCalledTimes(1)
      spy.mockClear()

      SubmissionProgressBars.displayGrade({...submission, grade: 'incomplete'})
      expect(spy).toHaveBeenCalledTimes(1)
      spy.mockRestore()
    })

    it('renders score/points_possible when grade is a random string', () => {
      const submission = {
        grade: 'A+',
        score: '15',
        id: '1',
        excused: false,
        assignment: {points_possible: 25},
      }
      expect(SubmissionProgressBars.displayGrade(submission)).toBe('15/25')
    })

    it('renders score/points_possible by default', () => {
      const submission = {
        grade: '15',
        score: '15',
        id: '1',
        excused: false,
        assignment: {points_possible: 25},
      }
      expect(SubmissionProgressBars.displayGrade(submission)).toBe('15/25')
    })
  })

  describe('displayScreenreaderGrade', () => {
    it('returns excused when submission is excused', () => {
      const submission = {id: '1', excused: true, assignment: {points_possible: 25}}
      expect(SubmissionProgressBars.displayScreenreaderGrade(submission)).toBe('excused')
    })

    it('returns the grade when it is a percentage', () => {
      const percentage = '80%'
      const submission = {
        id: '1',
        excused: false,
        grade: percentage,
        assignment: {points_possible: 25},
      }
      expect(SubmissionProgressBars.displayScreenreaderGrade(submission)).toBe(percentage)
    })

    it('returns complete or incomplete when grade is complete/incomplete', () => {
      const submission = {
        id: '1',
        excused: false,
        assignment: {points_possible: 25},
      }

      expect(
        SubmissionProgressBars.displayScreenreaderGrade({...submission, grade: 'complete'}),
      ).toBe('complete')
      expect(
        SubmissionProgressBars.displayScreenreaderGrade({...submission, grade: 'incomplete'}),
      ).toBe('incomplete')
    })

    it('renders score/points_possible when grade is a random string', () => {
      const submission = {
        grade: 'A+',
        score: '15',
        id: '1',
        excused: false,
        assignment: {points_possible: 25},
      }
      expect(SubmissionProgressBars.displayScreenreaderGrade(submission)).toBe('15/25')
    })

    it('renders score/points_possible by default with proper rounding', () => {
      const submission = {
        grade: '15',
        score: '15.56789',
        id: '1',
        excused: false,
        assignment: {points_possible: 25},
      }
      expect(SubmissionProgressBars.displayScreenreaderGrade(submission)).toBe('15.57/25')
    })
  })

  describe('renderIcon', () => {
    it('renders icon with icon-check class when grade is complete', () => {
      const submission = {
        id: '1',
        grade: 'complete',
        score: 25,
        assignment: {name: 'test', points_possible: 25, html_url: '/test'},
        user,
      }
      render(<SubmissionProgressBars submissions={[submission]} />)
      expect(screen.getByTestId('submission-grade-icon-complete')).toHaveClass('icon-check')
    })

    it('renders icon with icon-x class when grade is incomplete', () => {
      const submission = {
        id: '1',
        grade: 'incomplete',
        score: 0,
        assignment: {name: 'test', points_possible: 25, html_url: '/test'},
        user,
      }
      render(<SubmissionProgressBars submissions={[submission]} />)
      expect(screen.getByTestId('submission-grade-icon-incomplete')).toHaveClass('icon-x')
    })
  })

  describe('render', () => {
    it('renders one progress bar per submission', () => {
      const submissions = [
        {
          id: '1',
          grade: 'incomplete',
          score: 0,
          user,
          assignment: {name: 'test', points_possible: 25, html_url: '/test'},
        },
        {
          id: '2',
          grade: 'complete',
          score: 25,
          user,
          assignment: {name: 'test', points_possible: 25, html_url: '/test'},
        },
        {
          id: '3',
          grade: 'A+',
          score: 25,
          user,
          assignment: {name: 'test', points_possible: 25, html_url: '/test'},
        },
      ]
      render(<SubmissionProgressBars submissions={submissions} />)
      expect(screen.getAllByTestId('submission-progress-bar')).toHaveLength(submissions.length)
    })

    it('ignores submissions with null grades', () => {
      const submissions = [
        {
          id: '1',
          score: 5,
          grade: '5',
          assignment: {name: 'test', html_url: '/test', points_possible: 1},
          user: {short_name: 'bob', _id: '1'},
        },
        {
          id: '2',
          score: null,
          grade: null,
          assignment: {name: 'test', html_url: '/test', points_possible: 1},
          user: {short_name: 'bob', _id: '1'},
        },
      ]

      render(<SubmissionProgressBars submissions={submissions} />)
      expect(screen.getAllByTestId('submission-progress-bar')).toHaveLength(1)
    })

    it('links to submission urls', () => {
      const submissions = [
        {
          id: '1',
          score: 5,
          grade: '5',
          assignment: {name: 'test', html_url: 'grades', points_possible: 1},
          user: {short_name: 'bob', _id: '99'},
        },
      ]

      render(<SubmissionProgressBars submissions={submissions} />)
      expect(screen.getByTestId('submission-link')).toHaveAttribute('href', 'grades/submissions/99')
    })
  })
})

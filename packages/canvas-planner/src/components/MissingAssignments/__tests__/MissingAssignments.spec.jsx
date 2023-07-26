/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {act, render} from '@testing-library/react'

import {convertSubmissionType, getMissingItemsText, MissingAssignments} from '..'

const defaultProps = (expanded = false) => ({
  courses: [
    {
      id: '18',
      originalName: 'Nuclear Fission for Beginners',
      color: '#123456',
    },
    {
      id: '19',
      originalName: 'Mac-to-Basics: Remedial Macramé',
      color: '#ABCDEF',
    },
  ],
  loadingOpportunities: false,
  opportunities: {
    items: [
      {
        id: '3',
        name: 'My First Reactor',
        points_possible: 10,
        html_url: '/courses/18/assignments/3',
        due_at: '2019-07-10T05:59:00Z',
        submission_types: ['online_url'],
        course_id: '18',
      },
      {
        id: '12',
        name: 'How to Tie a Knot',
        points_possible: 3,
        html_url: '/courses/19/assignments/12',
        due_at: '2020-10-10T05:59:00Z',
        submission_types: ['online_quiz'],
        course_id: '19',
      },
      {
        id: '22',
        name: 'Why Nuclear?',
        points_possible: 5,
        html_url: '/courses/18/assignments/22',
        due_at: '2020-12-10T05:59:00Z',
        submission_types: ['discussion_topic'],
        course_id: '18',
      },
    ],
    missingItemsExpanded: expanded,
    nextUrl: null,
  },
  responsiveSize: 'large',
  timeZone: 'Pacific/Guam',
  toggleMissing: jest.fn(),
})

describe('MissingAssignments', () => {
  it('Renders nothing if there are no opportunities', () => {
    const {queryByRole} = render(
      <MissingAssignments {...defaultProps()} opportunities={{items: []}} />
    )
    expect(queryByRole('button', {name: /missing items/})).not.toBeInTheDocument()
  })

  describe('when collapsed', () => {
    it('Renders a Show button with the number of opportunities if there are opportunities', () => {
      const {getByRole} = render(<MissingAssignments {...defaultProps()} />)
      expect(getByRole('button', {name: 'Show 3 missing items'})).toBeInTheDocument()
    })

    it('Renders a warning icon next to the Show button when collapsed', () => {
      const {getByTestId} = render(<MissingAssignments {...defaultProps()} />)
      expect(getByTestId('warning-icon')).toBeInTheDocument()
    })

    it('Expands to show a list of missing assignments when the Show button is clicked', async () => {
      const props = defaultProps()
      const {getByRole} = render(<MissingAssignments {...props} />)
      act(() => getByRole('button', {name: 'Show 3 missing items'}).click())
      expect(props.toggleMissing).toHaveBeenCalled()

      const {getByText} = render(<MissingAssignments {...defaultProps(true)} />)
      expect(document.getElementsByClassName('planner-item').length).toBe(3)
      expect(getByText('My First Reactor')).toBeInTheDocument()
      expect(getByText('How to Tie a Knot')).toBeInTheDocument()
      expect(getByText('Why Nuclear?')).toBeInTheDocument()
    })
  })

  describe('when expanded', () => {
    it('Renders differently for discussions, quizzes, and assignments', () => {
      const {getByText} = render(<MissingAssignments {...defaultProps(true)} />)

      expect(
        getByText('Assignment My First Reactor, due Wednesday, July 10, 2019 3:59 PM.')
      ).toBeInTheDocument()
      expect(
        getByText('Quiz How to Tie a Knot, due Saturday, October 10, 2020 3:59 PM.')
      ).toBeInTheDocument()
      expect(
        getByText('Discussion Why Nuclear?, due Thursday, December 10, 2020 3:59 PM.')
      ).toBeInTheDocument()
    })

    it('Does not render a warning icon next to the Hide button when expanded', () => {
      const {queryByTestId} = render(<MissingAssignments {...defaultProps(true)} />)

      expect(queryByTestId('warning-icon')).not.toBeInTheDocument()
    })
  })

  describe('convertSubmissionType', () => {
    it('converts submission_type of discussion_topic to Discussion', () => {
      expect(convertSubmissionType(['discussion_topic'])).toBe('Discussion')
    })

    it('converts submission_type of online_quiz to Quiz', () => {
      expect(convertSubmissionType(['online_quiz'])).toBe('Quiz')
    })

    it('converts all other submission types to Assignment', () => {
      expect(convertSubmissionType(['online_upload'])).toBe('Assignment')
      expect(convertSubmissionType(['online_text_entry'])).toBe('Assignment')
      expect(convertSubmissionType(['online_url'])).toBe('Assignment')
      expect(convertSubmissionType(['media_recording'])).toBe('Assignment')
      expect(convertSubmissionType(['fake_thing'])).toBe('Assignment')
    })

    it('only looks at the first submission type', () => {
      expect(convertSubmissionType(['discussion_topic', 'online_quiz'])).toBe('Discussion')
    })
  })

  describe('getMissingItemsText', () => {
    it('Has a different call to action based on whether the state is expanded or collapsed', () => {
      expect(getMissingItemsText(true, 1)).toBe('Hide 1 missing item')
      expect(getMissingItemsText(false, 1)).toBe('Show 1 missing item')
    })

    it('Pluralizes correctly', () => {
      expect(getMissingItemsText(true, 1)).toBe('Hide 1 missing item')
      expect(getMissingItemsText(true, 2)).toBe('Hide 2 missing items')
      expect(getMissingItemsText(true, 37)).toBe('Hide 37 missing items')
    })
  })
})

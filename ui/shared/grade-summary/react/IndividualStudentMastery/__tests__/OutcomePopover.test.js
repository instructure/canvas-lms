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
import {render, fireEvent, within} from '@testing-library/react'
import OutcomePopover from '../OutcomePopover'

const time1 = new Date('1995-12-17T03:24:00Z')
const time2 = new Date('1999-03-11T12:20:00Z')

const defaultProps = (props = {}) => ({
  outcome: {
    id: 1,
    assignments: [],
    expansionId: 100,
    mastered: false,
    mastery_points: 3,
    points_possible: 5,
    calculation_method: 'highest',
    score: 3,
    ratings: [
      {description: 'My first rating', mastery: true},
      {description: 'My second rating', mastery: false},
    ],
    results: [
      {
        id: 1,
        score: 1,
        percent: 0.1,
        assignment: {
          id: 1,
          html_url: 'http://foo',
          name: 'My assignment',
          submission_types: 'online_quiz',
          score: 0,
        },
        submitted_or_assessed_at: time1,
      },
      {
        id: 1,
        score: 7,
        percent: 0.7,
        assignment: {
          id: 2,
          html_url: 'http://bar',
          name: 'Assignment 2',
          submission_types: 'online_quiz',
          score: 3,
        },
        submitted_or_assessed_at: time2,
      },
    ],
    title: 'My outcome',
    friendly_description: '',
  },
  outcomeProficiency: {
    ratings: [
      {color: 'blue', description: 'I am blue', points: 10, mastery: false},
      {color: 'green', description: 'I am Groot', points: 5, mastery: true},
      {color: 'red', description: 'I am red', points: 0, mastery: false},
    ],
  },
  ...props,
})

it('renders the OutcomePopover component', () => {
  const {getByText} = render(<OutcomePopover {...defaultProps()} />)
  expect(getByText(/Click to expand/)).not.toBeNull()
})

describe('modal mode', () => {
  it('shows details on click', () => {
    const {baseElement, getByRole} = render(<OutcomePopover {...defaultProps()} />)
    const button = getByRole('button')
    fireEvent.click(button)
    expect(within(baseElement).getByText('Calculation Method')).not.toBeNull()
  })
})

describe('popover mode', () => {
  it('shows details on click', () => {
    const {baseElement, getByRole} = render(
      <OutcomePopover {...defaultProps()} breakpoints={{miniTablet: true}} />
    )
    const button = getByRole('button')
    fireEvent.click(button)
    expect(within(baseElement).getByText('Calculation Method')).not.toBeNull()
  })

  it('shows details on hover', () => {
    const {baseElement, getByRole} = render(
      <OutcomePopover {...defaultProps()} breakpoints={{miniTablet: true}} />
    )
    const button = getByRole('button')
    fireEvent.mouseEnter(button)
    expect(within(baseElement).getByText('Calculation Method')).not.toBeNull()
  })

  it('removes details on leave', () => {
    const {baseElement, getByRole} = render(
      <OutcomePopover {...defaultProps()} breakpoints={{miniTablet: true}} />
    )
    const button = getByRole('button')
    fireEvent.mouseEnter(button)
    fireEvent.mouseLeave(button)
    expect(within(baseElement).queryByText('Calculation Method')).toBeNull()
  })
})

describe('latest time', () => {
  it('renders correctly with no results', () => {
    const props = defaultProps()
    props.outcome.results = []
    const {baseElement, getByRole} = render(<OutcomePopover {...props} />)
    const button = getByRole('button')
    fireEvent.click(button)
    expect(within(baseElement).getByText('Last Assessment: No submissions')).not.toBeNull()
  })

  it('properly returns the most recent submission time', () => {
    const {baseElement, getByRole} = render(<OutcomePopover {...defaultProps()} />)
    const button = getByRole('button')
    fireEvent.click(button)
    expect(within(baseElement).getByText(/Mar 11/)).not.toBeNull()
  })
})

describe('selected rating', () => {
  it('renders custom outcomeProficiency', () => {
    const {baseElement, getByRole} = render(<OutcomePopover {...defaultProps()} />)
    const button = getByRole('button')
    fireEvent.click(button)
    expect(within(baseElement).getByText('I am Groot')).not.toBeNull()
  })

  it('renders correct last assessment time with no custom outcomeProficiency', () => {
    const props = defaultProps()
    props.outcomeProficiency = null
    const {baseElement, getByRole} = render(<OutcomePopover {...props} />)
    const button = getByRole('button')
    fireEvent.click(button)
    expect(within(baseElement).getByText('Meets Mastery')).not.toBeNull()
  })
})

describe('friendly description', () => {
  it('renders the friendly description if the outcome has one', () => {
    const friendlyDescription = {
      ...defaultProps().outcome,
      ...{friendly_description: 'A friendly description'},
    }
    const {baseElement, getByRole} = render(
      <OutcomePopover {...defaultProps({outcome: friendlyDescription})} />
    )
    const button = getByRole('button')
    fireEvent.click(button)
    expect(within(baseElement).getByText('A friendly description')).not.toBeNull()
  })
})

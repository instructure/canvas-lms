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
import {Set} from 'immutable'
import OutcomeGroup from '../OutcomeGroup'

const outcome = (id, title) => ({
  id,
  title,
  assignments: [
    {html_url: 'http://foo', id: 'assignment_2', name: 'My alignment', submission_types: 'none'},
  ],
  mastered: false,
  mastery_points: 3,
  points_possible: 5,
  calculation_method: 'highest',
  ratings: [{description: 'My first rating'}, {description: 'My second rating'}],
  results: [
    {
      id: 1,
      percent: 0.1,
      assignment: {
        id: 'assignment_2',
        name: 'My alignment',
        html_url: 'http://foo',
        submission_types: '',
      },
    },
  ],
})

const defaultProps = (props = {}) => ({
  outcomeGroup: {
    id: 10,
    title: 'My group',
  },
  outcomes: [outcome(1, 'My outcome')],
  expanded: false,
  expandedOutcomes: Set(),
  onExpansionChange: () => {},
  ...props,
})

it('renders the OutcomeGroup component', () => {
  const {getByText} = render(<OutcomeGroup {...defaultProps()} />)
  expect(getByText('My group')).not.toBeNull()
})

it('includes the individual outcomes', () => {
  const {getByText} = render(<OutcomeGroup {...defaultProps()} expanded={true} />)
  expect(getByText('My outcome')).not.toBeNull()
})

it('renders outcomes in alphabetical order by title', () => {
  const props = defaultProps({
    outcomes: [
      outcome(1, 'ZZ Top'),
      outcome(2, 'Aardvark'),
      outcome(3, 'abba'),
      outcome(4, 'Aerosmith'),
    ],
  })
  const {getAllByRole} = render(<OutcomeGroup {...props} expanded={true} />)
  const outcomes = getAllByRole('listitem')
  expect(outcomes).toHaveLength(4)
  expect(within(outcomes[0]).getByText('Aardvark')).not.toBeNull()
  expect(within(outcomes[1]).getByText('abba')).not.toBeNull()
  expect(within(outcomes[2]).getByText('Aerosmith')).not.toBeNull()
  expect(within(outcomes[3]).getByText('ZZ Top')).not.toBeNull()
})

describe('handleToggle()', () => {
  it('calls the correct onExpansionChange callback', () => {
    const props = defaultProps()
    props.onExpansionChange = jest.fn()
    const {getByRole} = render(<OutcomeGroup {...props} />)
    const button = getByRole('button')
    fireEvent.click(button)
    expect(props.onExpansionChange).toHaveBeenCalledWith('group', 10, true)
  })
})

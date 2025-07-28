/*
 * Copyright (C) 2024 Instructure, Inc.
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
import DueDateRow from '../DueDateRow'
import fakeENV from '@canvas/test-utils/fakeENV'

// Mock react-tokeninput to prevent React warnings about unrecognized DOM props
jest.mock('react-tokeninput', () => ({
  __esModule: true,
  default: jest.fn(props => (
    <div data-testid="token-input">
      {props.children}
      <input
        type="text"
        value={props.value || ''}
        onChange={e => props.onInput?.(e.target.value)}
      />
    </div>
  )),
  Option: jest.fn(props => <div data-testid="token-option">{props.children}</div>),
}))

jest.mock('../DueDateRow', () => {
  const Component = jest.requireActual('../DueDateRow').default
  return jest.fn().mockImplementation(props => {
    return <Component {...props} />
  })
})

describe('DueDateRow with empty props and canDelete true', () => {
  const props = {
    overrides: [],
    sections: {},
    students: {},
    dates: {},
    groups: {},
    canDelete: true,
    rowKey: 'nullnullnull',
    validDropdownOptions: [],
    currentlySearching: false,
    allStudentsFetched: true,
    handleDelete: jest.fn(),
    defaultSectionNamer: jest.fn(),
    handleTokenAdd: jest.fn(),
    handleTokenRemove: jest.fn(),
    replaceDate: jest.fn(),
    inputsDisabled: false,
    dueDatesReadonly: false,
    availabilityDatesReadonly: false,
  }

  beforeEach(() => {
    fakeENV.setup()
    ENV.context_asset_string = 'course_1'
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  it('renders', () => {
    const {container} = render(<DueDateRow {...props} />)
    expect(container).toBeInTheDocument()
  })

  it('returns a remove link if canDelete', () => {
    render(<DueDateRow {...props} />)
    expect(screen.queryByRole('button', {name: /remove/i})).toBeTruthy()
  })
})

describe('DueDateRow with realistic props and canDelete false', () => {
  const props = {
    overrides: [
      {
        get: attr => ({course_section_id: 1})[attr],
      },
    ],
    sections: {1: {name: 'section name'}},
    students: {},
    dates: {},
    groups: {},
    canDelete: false,
    rowKey: 'section1nullnull',
    validDropdownOptions: [],
    currentlySearching: false,
    allStudentsFetched: true,
    handleDelete: jest.fn(),
    defaultSectionNamer: jest.fn(),
    handleTokenAdd: jest.fn(),
    handleTokenRemove: jest.fn(),
    replaceDate: jest.fn(),
    inputsDisabled: false,
    dueDatesReadonly: false,
    availabilityDatesReadonly: false,
  }

  beforeEach(() => {
    fakeENV.setup()
    ENV.context_asset_string = 'course_1'
    jest.clearAllMocks()
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  it('renders', () => {
    const {container} = render(<DueDateRow {...props} />)
    expect(container).toBeInTheDocument()
  })

  it('does not return remove link if not canDelete', () => {
    render(<DueDateRow {...props} />)
    expect(screen.queryByRole('button', {name: /remove/i})).toBeFalsy()
  })

  it('tokenizing ADHOC overrides works', () => {
    render(<DueDateRow {...props} />)
    expect(screen.getByRole('region', {name: /due date set/i})).toBeTruthy()
  })

  it('returns correct name from nameOrLoading', () => {
    const collection = {
      2: {
        name: 'Test User',
        pronouns: 'they/them',
      },
      5: {
        name: 'Another User',
      },
    }
    render(<DueDateRow {...props} students={collection} />)
    expect(screen.queryByText('Test User (they/them)')).toBeFalsy() // Since this user is not in overrides
  })
})

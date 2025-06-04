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
import {render, fireEvent} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import DueDateTokenWrapper from '../DueDateTokenWrapper'
import fakeENV from '@canvas/test-utils/fakeENV'

jest.mock('@canvas/user-settings', () => ({
  map: jest.fn(),
  get: jest.fn(),
  set: jest.fn(),
}))

// Mock OverrideStudentStore
jest.mock('../OverrideStudentStore', () => ({
  fetchStudentsForCourse: jest.fn(),
  fetchStudentsByName: jest.fn(),
  getContextPath: jest.fn(() => '/courses/1'),
}))

describe('DueDateTokenWrapper', () => {
  let props
  const user = userEvent.setup()

  beforeEach(() => {
    fakeENV.setup('course_1')
    window.ENV = {
      FEATURES: {instui_nav: false},
      current_user_id: '12345',
      context_asset_string: 'course_1',
    }

    props = {
      tokens: [
        {id: '1', name: 'Atilla', student_id: '3', type: 'student'},
        {id: '2', name: 'Huns', course_section_id: '4', type: 'section'},
        {id: '3', name: 'Reading Group 3', group_id: '3', type: 'group'},
      ],
      potentialOptions: [
        {course_section_id: '1', name: 'Patricians'},
        {id: '1', name: 'Seneca The Elder', displayName: 'Seneca The Elder'},
        {id: '2', name: 'Agrippa', displayName: 'Agrippa'},
        {id: '3', name: 'Publius', displayName: 'Publius (publius@example.com)'},
        {id: '4', name: 'Scipio', displayName: 'Scipio'},
        {id: '5', name: 'Baz', displayName: 'Baz'},
        {id: '6', name: 'Publius', displayName: 'Publius (pub123)'},
        {course_section_id: '2', name: 'Plebs | [$'},
        {course_section_id: '3', name: 'Foo'},
        {course_section_id: '4', name: 'Bar'},
        {course_section_id: '5', name: 'Baz'},
        {course_section_id: '6', name: 'Qux'},
        {group_id: '1', name: 'Reading Group One'},
        {group_id: '2', name: 'Reading Group Two'},
        {noop_id: '1', name: 'Mastery Paths'},
      ],
      handleTokenAdd: jest.fn(),
      handleTokenRemove: jest.fn(),
      defaultSectionNamer: jest.fn(),
      allStudentsFetched: false,
      currentlySearching: false,
      rowKey: 'nullnullnull',
      disabled: false,
    }
  })

  afterEach(() => {
    fakeENV.teardown()
    jest.clearAllMocks()
  })

  it('renders the token input', () => {
    const {container} = render(<DueDateTokenWrapper {...props} />)
    expect(container.querySelector('.ic-tokeninput')).toBeInTheDocument()
  })

  it('displays student display names in options', () => {
    const {getAllByRole} = render(<DueDateTokenWrapper {...props} />)
    const publiusOptions = getAllByRole('option', {name: /Publius/})
    expect(publiusOptions).toHaveLength(2)
    expect(publiusOptions[0]).toHaveTextContent('Publius (publius@example.com)')
    expect(publiusOptions[1]).toHaveTextContent('Publius (pub123)')
  })

  it.skip('calls handleInput and fetchStudents on input changes', async () => {
    const {container} = render(<DueDateTokenWrapper {...props} />)
    const input = container.querySelector('.ic-tokeninput-input')

    await user.type(input, 'to')
    fireEvent.change(input, {target: {value: 'to'}})
    expect(props.handleTokenAdd).toHaveBeenCalledTimes(1)

    await user.type(input, 'tre')
    fireEvent.change(input, {target: {value: 'tre'}})
    expect(props.handleTokenAdd).toHaveBeenCalledTimes(2)
  })

  it('filters options based on user input', async () => {
    const {container, getAllByRole} = render(<DueDateTokenWrapper {...props} />)
    const input = container.querySelector('.ic-tokeninput-input')

    await user.type(input, 'scipio')
    fireEvent.change(input, {target: {value: 'scipio'}})
    const filteredOptions = getAllByRole('option', {name: /Scipio/})
    expect(filteredOptions).toHaveLength(1)
  })

  it('groups menu options by type', () => {
    const {getAllByRole} = render(<DueDateTokenWrapper {...props} />)
    const options = getAllByRole('option')

    const courseSection = options.find(option => option.textContent === 'Course Section')
    const group = options.find(option => option.textContent === 'Group')
    const student = options.find(option => option.textContent === 'Student')

    expect(courseSection).toBeInTheDocument()
    expect(group).toBeInTheDocument()
    expect(student).toBeInTheDocument()
  })

  it.skip('calls handleTokenAdd when a token is added', async () => {
    const {container} = render(<DueDateTokenWrapper {...props} />)
    const input = container.querySelector('.ic-tokeninput-input')

    await user.type(input, 'sene')
    fireEvent.change(input, {target: {value: 'sene'}})
    fireEvent.keyDown(input, {key: 'Enter', code: 'Enter'})
    expect(props.handleTokenAdd).toHaveBeenCalled()
  })

  it('calls handleTokenRemove when a token is removed', async () => {
    const {getAllByRole} = render(<DueDateTokenWrapper {...props} />)
    const removeButtons = getAllByRole('button', {name: /Currently assigned to.*click to remove/})

    await user.click(removeButtons[0])
    expect(props.handleTokenRemove).toHaveBeenCalled()
  })

  it('matches tokens with special characters', async () => {
    const {container, getAllByRole} = render(<DueDateTokenWrapper {...props} />)
    const input = container.querySelector('.ic-tokeninput-input')

    await user.type(input, 'Plebs')
    fireEvent.change(input, {target: {value: 'Plebs'}})
    const options = getAllByRole('option', {name: /Plebs/})
    expect(options[0]).toHaveTextContent('Plebs | [$')
  })

  it('matches tokens by middle of string', async () => {
    const {container, getAllByRole} = render(<DueDateTokenWrapper {...props} />)
    const input = container.querySelector('.ic-tokeninput-input')

    await user.type(input, 'The Elder')
    fireEvent.change(input, {target: {value: 'The Elder'}})
    const options = getAllByRole('option', {name: /The Elder/})
    expect(options[0]).toHaveTextContent('Seneca The Elder')
  })
})

describe('Disabled DueDateTokenWrapper', () => {
  let props

  beforeEach(() => {
    fakeENV.setup('course_1')
    window.ENV = {
      FEATURES: {instui_nav: false},
      current_user_id: '12345',
      context_asset_string: 'course_1',
    }

    props = {
      tokens: [{id: '1', name: 'Atilla', student_id: '3', type: 'student'}],
      potentialOptions: [{course_section_id: '1', name: 'Patricians'}],
      handleTokenAdd: jest.fn(),
      handleTokenRemove: jest.fn(),
      defaultSectionNamer: jest.fn(),
      allStudentsFetched: false,
      currentlySearching: false,
      rowKey: 'wat',
      disabled: true,
    }
  })

  afterEach(() => {
    fakeENV.teardown()
    jest.clearAllMocks()
  })

  it.skip('renders a disabled token input', () => {
    const {container} = render(<DueDateTokenWrapper {...props} />)
    const input = container.querySelector('.ic-tokeninput-input')
    expect(input).toBeInTheDocument()
    expect(input).toHaveAttribute('disabled')
  })
})

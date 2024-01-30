/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {render, act} from '@testing-library/react'

import ContextSelector from '../ContextSelector'

const COURSE_1 = {
  id: '1',
  name: 'testcourse',
  asset_string: 'course_1',
  can_create_appointment_groups: true,
  sections: [
    {
      id: '1',
      asset_string: 'course_section_1',
      name: 'testsection',
      can_create_appointment_groups: true
    },
    {
      id: '3',
      asset_string: 'course_section_3',
      name: 'testsection3',
      can_create_appointment_groups: true
    },
  ],
}

const COURSE_2 = {
  id: '2',
  name: 'testcourse2',
  asset_string: 'course_2',
  can_create_appointment_groups: true,
  sections: [
    {
      id: '2',
      asset_string: 'course_section_2',
      name: 'testsection2',
      can_create_appointment_groups: true
    },
  ],
}

const DEFAULT_PROPS = {
  contexts: [COURSE_1, COURSE_2],
  appointmentGroup: {context_codes: [], sub_context_codes: []},
  selectedContexts: new Set(),
  selectedSubContexts: new Set(),
  setSelectedContexts: () => {},
  setSelectedSubContexts: () => {},
}

describe('Other Calendars modal ', () => {
  it('opens and closes the dropdown', () => {
    const {getByTestId, getByRole} = render(<ContextSelector {...DEFAULT_PROPS} />)
    const button = getByRole('button', {name: 'Select Calendars'})
    expect(button).toBeInTheDocument()
    const dropdown = getByTestId('context-selector-dropdown')
    expect(dropdown.classList.contains('hidden')).toBe(true)
    act(() => button.click())
    expect(dropdown.classList.contains('hidden')).toBe(false)
  })

  it('renders courses in the dropdown', () => {
    const {getByText, getByRole} = render(<ContextSelector {...DEFAULT_PROPS} />)
    act(() => getByRole('button', {name: 'Select Calendars'}).click())
    expect(getByText('testcourse')).toBeInTheDocument()
  })

  it('shows sections in the dropdown when expanded', () => {
    const {getByText, getByRole} = render(<ContextSelector {...DEFAULT_PROPS} />)
    act(() => getByRole('button', {name: 'Select Calendars'}).click())
    const testcourse = getByRole('button', {name: 'Expand testcourse'})
    expect(testcourse).toBeInTheDocument()
    const testsection = getByText('testsection').closest(`div#course_${COURSE_1.id}_sections`)
    expect(testsection.classList.contains('hiddenSection')).toBe(true)
    act(() => testcourse.click())
    expect(testsection.classList.contains('hiddenSection')).toBe(false)
  })

  it('calls setSelectedContexts when a course is selected', () => {
    const setSelectedContexts = jest.fn()
    const {getByText, getByRole, rerender} = render(
      <ContextSelector {...DEFAULT_PROPS} setSelectedContexts={setSelectedContexts} />
    )
    act(() => getByRole('button', {name: 'Select Calendars'}).click())
    act(() => getByText('testcourse').click())
    expect(setSelectedContexts).toHaveBeenCalledWith(new Set(['course_1']))
    rerender(
      <ContextSelector
        {...DEFAULT_PROPS}
        setSelectedContexts={setSelectedContexts}
        selectedContexts={new Set(['course_1'])}
      />
    )
    act(() => getByText('testcourse2').click())
    expect(setSelectedContexts).toHaveBeenCalledWith(new Set(['course_1', 'course_2']))
  })

  it('toggles parent context when a section is selected', () => {
    const setSelectedContexts = jest.fn()
    const setSelectedSubContexts = jest.fn()
    const {getByText, getByRole, getByLabelText, rerender} = render(
      <ContextSelector
        {...DEFAULT_PROPS}
        setSelectedContexts={setSelectedContexts}
        setSelectedSubContexts={setSelectedSubContexts}
      />
    )
    act(() => getByRole('button', {name: 'Select Calendars'}).click())
    act(() => getByText('testsection').click())
    expect(setSelectedContexts).toHaveBeenCalledWith(new Set(['course_1']))
    expect(setSelectedSubContexts).toHaveBeenCalledWith(new Set(['course_section_1']))
  })

  it('checks checkboxes next to selected contexts', () => {
    const {getByLabelText} = render(
      <ContextSelector
        {...DEFAULT_PROPS}
        selectedContexts={new Set(['course_1', 'course_2'])}
        selectedSubContexts={new Set(['course_section_1'])}
      />
    )
    expect(getByLabelText('testcourse')).toBeChecked()
    expect(getByLabelText('testcourse2')).toBeChecked()
    expect(getByLabelText('testsection')).toBeChecked()
    expect(getByLabelText('testsection2')).toBeChecked()
    expect(getByLabelText('testsection3')).not.toBeChecked()
  })

  it('renders the button label according to the number of selected contexts', () => {
    const {getByRole, rerender} = render(
      <ContextSelector {...DEFAULT_PROPS} selectedContexts={new Set(['course_1'])} />
    )
    expect(getByRole('button', {name: 'testcourse'})).toBeInTheDocument()
    rerender(
      <ContextSelector {...DEFAULT_PROPS} selectedContexts={new Set(['course_1', 'course_2'])} />
    )
    expect(getByRole('button', {name: 'testcourse and 1 other'})).toBeInTheDocument()
  })
})

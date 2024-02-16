// @ts-nocheck
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
import FilterNavFilter from '../FilterTrayFilter'
import type {FilterNavFilterProps} from '../FilterTrayFilter'
import {render, fireEvent} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import '@testing-library/jest-dom/extend-expect'

const defaultProps: FilterNavFilterProps = {
  modules: [],
  gradingPeriods: [],
  assignmentGroups: [],
  sections: [],
  studentGroupCategories: {},
  onChange: jest.fn(),
  filter: {
    id: '123',
    type: 'submissions',
    value: 'has-ungraded-submissions',
    created_at: '2021-11-02T20:56:23.616Z',
  },
}

const dateTests = (testType: string) => {
  let props, filter, onChange, onDelete
  beforeEach(() => {
    filter = {
      id: '456',
      createdAt: '2021-11-02T20:56:23.616Z',
      type: testType,
      value: undefined,
    }
    props = {
      ...defaultProps,
      filter,
    }
    onChange = jest.fn()
    onDelete = jest.fn()
  })

  it('renders a date field', () => {
    const {getByTestId} = render(
      <FilterNavFilter {...props} onChange={onChange} onDelete={onDelete} />
    )
    const dateComponent: Partial<HTMLInputElement> = getByTestId(`${filter.type}-input`)
    expect(dateComponent).toBeInTheDocument()
  })

  it('sets the date field value if the filter value is present', () => {
    filter.value = '2021-12-03T02:00:00-0500'
    props.filter = filter
    const {getByTestId} = render(
      <FilterNavFilter {...props} onChange={onChange} onDelete={onDelete} />
    )
    const dateComponent: Partial<HTMLInputElement> = getByTestId(`${filter.type}-input`)
    expect(dateComponent.value).toContain('Dec 3, 2021')
  })

  it('changing the date input value triggers onChange', async () => {
    const {getByTestId} = render(
      <FilterNavFilter {...props} onChange={onChange} onDelete={onDelete} />
    )
    const dateComponent = getByTestId(`${filter.type}-input`)
    fireEvent.change(dateComponent, {
      target: {value: 'Dec 04, 2021'},
    })
    fireEvent.blur(dateComponent)
    expect(onChange).toHaveBeenCalled()
  })
}

describe('FilterNavFilter', () => {
  describe('Start Date', () => {
    dateTests('start-date')
  })
  describe('End Date', () => {
    dateTests('end-date')
  })

  describe('submissions', () => {
    let props, filter, onChange, onDelete
    beforeEach(() => {
      filter = {
        id: '456',
        createdAt: '2021-11-02T20:56:23.616Z',
        type: 'submissions',
        value: undefined,
      }
      props = {
        ...defaultProps,
        filter,
      }
      onChange = jest.fn()
      onDelete = jest.fn()
    })

    it('renders filters for submissions', () => {
      const {getByRole} = render(
        <FilterNavFilter {...props} onChange={onChange} onDelete={onDelete} />
      )
      const button = getByRole('combobox', {name: 'Submissions'})
      expect(button).toBeInTheDocument()
    })

    it('sets the submissions field if value is present', () => {
      filter.value = 'has-ungraded-submissions'
      const {getByRole} = render(
        <FilterNavFilter {...props} onChange={onChange} onDelete={onDelete} />
      )
      const button: Partial<HTMLButtonElement> = getByRole('combobox', {name: 'Submissions'})
      expect(button?.value).toContain('Has ungraded submissions')
    })

    it('changing value triggers onChange', async () => {
      const {getByRole} = render(
        <FilterNavFilter {...props} onChange={onChange} onDelete={onDelete} />
      )
      await userEvent.click(getByRole('combobox', {name: 'Submissions'}))
      await userEvent.click(getByRole('option', {name: 'Has ungraded submissions'}))
      expect(onChange).toHaveBeenLastCalledWith(
        expect.objectContaining({
          type: 'submissions',
          value: 'has-ungraded-submissions',
        })
      )
    })
  })

  describe('sections', () => {
    let props, filter, onChange, onDelete
    beforeEach(() => {
      filter = {
        id: '456',
        createdAt: '2021-11-02T20:56:23.616Z',
        type: 'section',
        value: '1',
      }
      props = {
        ...defaultProps,
        filter,
        sections: [
          {id: '1', name: 'Section 1'},
          {id: '2', name: 'Section 2'},
        ],
      }
      onChange = jest.fn()
      onDelete = jest.fn()
    })

    it('sets the sections field if value is present', () => {
      filter.value = '1'
      const {getByRole} = render(
        <FilterNavFilter {...props} onChange={onChange} onDelete={onDelete} />
      )
      const button: Partial<HTMLButtonElement> = getByRole('combobox', {name: 'Sections'})
      expect(button.value).toContain('Section 1')
    })

    it('changing value triggers onChange', async () => {
      const {getByRole} = render(
        <FilterNavFilter {...props} onChange={onChange} onDelete={onDelete} />
      )
      await userEvent.click(getByRole('combobox', {name: 'Sections'}))
      await userEvent.click(getByRole('option', {name: 'Section 1'}))
      expect(onChange).toHaveBeenLastCalledWith(
        expect.objectContaining({
          id: '456',
          type: 'section',
          value: '1',
        })
      )
    })
  })

  describe('grading periods', () => {
    let props, filter, onChange, onDelete
    beforeEach(() => {
      filter = {
        id: '456',
        createdAt: '2021-11-02T20:56:23.616Z',
        type: 'grading-period',
        value: '1',
      }
      props = {
        ...defaultProps,
        filter,
        gradingPeriods: [
          {id: '1', title: 'Grading Period 1', startDate: 1},
          {id: '2', title: 'Grading Period 2', startDate: 2},
          {id: '3', title: 'Grading Period 3', startDate: 3},
        ],
      }
      onChange = jest.fn()
      onDelete = jest.fn()
    })

    it('sets the grading periods field if value is present', () => {
      filter.value = '1'
      const {getByRole} = render(
        <FilterNavFilter {...props} onChange={onChange} onDelete={onDelete} />
      )
      const button: Partial<HTMLButtonElement> = getByRole('combobox', {name: 'Grading Periods'})
      expect(button.value).toContain('Grading Period 1')
    })

    it('changing value triggers onChange', async () => {
      const {getByRole} = render(
        <FilterNavFilter {...props} onChange={onChange} onDelete={onDelete} />
      )
      await userEvent.click(getByRole('combobox', {name: 'Grading Periods'}))
      await userEvent.click(getByRole('option', {name: 'Grading Period 1'}))
      expect(onChange).toHaveBeenLastCalledWith(
        expect.objectContaining({
          id: '456',
          type: 'grading-period',
          value: '1',
        })
      )
    })
  })

  describe('student groups', () => {
    let props, filter, onChange, onDelete
    beforeEach(() => {
      filter = {
        id: '456',
        createdAt: '2021-11-02T20:56:23.616Z',
        type: 'student-group',
        value: '1',
      }
      props = {
        ...defaultProps,
        filter,
        studentGroupCategories: {
          '1': {
            id: '1',
            name: 'Student Group Category 1',
            groups: [
              {id: '1', name: 'Student Group 1'},
              {id: '2', name: 'Student Group 2'},
            ],
          },
          '2': {
            id: '2',
            name: 'Student Group Category 2',
            groups: [
              {id: '3', name: 'Student Group 3'},
              {id: '4', name: 'Student Group 4'},
            ],
          },
        },
      }
      onChange = jest.fn()
      onDelete = jest.fn()
    })

    it('sets the student group field if value is present', () => {
      filter.value = '1'
      const {getByRole} = render(
        <FilterNavFilter {...props} onChange={onChange} onDelete={onDelete} />
      )
      const button: Partial<HTMLButtonElement> = getByRole('combobox', {name: 'Student Groups'})
      expect(button.value).toContain('Student Group 1')
    })

    it('changing value triggers onChange', async () => {
      const {getByRole} = render(
        <FilterNavFilter {...props} onChange={onChange} onDelete={onDelete} />
      )
      await userEvent.click(getByRole('combobox', {name: 'Student Groups'}))
      await userEvent.click(getByRole('option', {name: 'Student Group 1'}))
      expect(onChange).toHaveBeenLastCalledWith(
        expect.objectContaining({
          id: '456',
          type: 'student-group',
          value: '1',
        })
      )
    })
  })
})

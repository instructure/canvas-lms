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
import FilterNavCondition from '../FilterNavCondition'
import {render, fireEvent} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import '@testing-library/jest-dom/extend-expect'

const defaultProps = {
  conditionsInFilter: [],
  modules: [],
  gradingPeriods: [],
  assignmentGroups: [],
  sections: [],
  studentGroupCategories: {}
}

const dateTests = (testType: string, dateFieldName: string) => {
  let props, condition, onChange, onDelete
  beforeEach(() => {
    condition = {
      id: '456',
      createdAt: '2021-11-02T20:56:23.616Z',
      type: testType,
      value: undefined
    }
    props = {
      ...defaultProps,
      condition
    }
    onChange = jest.fn()
    onDelete = jest.fn()
  })

  it('renders a date field', () => {
    const {getByTestId} = render(
      <FilterNavCondition {...props} onChange={onChange} onDelete={onDelete} />
    )
    const dateComponent: Partial<HTMLInputElement> = getByTestId('date-input')
    expect(dateComponent).toBeInTheDocument()
  })

  it('sets the date field value if the condition value is present', () => {
    condition.value = 'Fri Dec 03 2021 02:00:00 GMT-0500 (Colombia Standard Time)'
    props.condition = condition
    const {getByTestId} = render(
      <FilterNavCondition {...props} onChange={onChange} onDelete={onDelete} />
    )
    const dateComponent: Partial<HTMLInputElement> = getByTestId('date-input')
    expect(dateComponent.value).toContain('Dec 3, 2021')
  })

  it('changing the date input value triggers onChange', async () => {
    const {getByTestId} = render(
      <FilterNavCondition {...props} onChange={onChange} onDelete={onDelete} />
    )
    const dateComponent = getByTestId('date-input')
    fireEvent.change(dateComponent, {
      target: {value: 'Fri Dec 04 2021 02:00:00 GMT-0500 (Colombia Standard Time)'}
    })
    fireEvent.blur(dateComponent)
    expect(onChange).toHaveBeenCalled()
  })

  it(`does not allow to create two ${dateFieldName} conditions`, () => {
    props.condition.type = testType === 'start-date' ? 'end-date' : 'start-date'
    props.conditionsInFilter = [
      {
        id: '458',
        createdAt: '2021-11-02T20:56:23.616Z',
        type: testType,
        value: 'Fri Dec 05 2021 02:00:00 GMT-0500 (Colombia Standard Time)'
      }
    ]
    const {queryByRole} = render(
      <FilterNavCondition {...props} onChange={onChange} onDelete={onDelete} />
    )
    const select = queryByRole('button', {name: 'Condition type'})
    fireEvent.click(select!)
    const option = queryByRole('option', {name: dateFieldName})
    expect(option).not.toBeInTheDocument()
  })

  it(`keeps the ${dateFieldName} option available when the current selected type is ${dateFieldName}`, () => {
    props.conditionsInFilter = [condition]
    const {getByRole} = render(
      <FilterNavCondition {...props} onChange={onChange} onDelete={onDelete} />
    )
    const select = getByRole('button', {name: 'Condition type'})
    fireEvent.click(select)
    const option = getByRole('option', {name: dateFieldName})
    expect(option).toBeInTheDocument()
  })
}

describe('FilterNavCondition', () => {
  describe('Start Date', () => {
    dateTests('start-date', 'Start Date')
  })
  describe('End Date', () => {
    dateTests('end-date', 'End Date')
  })

  describe('submissions', () => {
    let props, condition, onChange, onDelete
    beforeEach(() => {
      condition = {
        id: '456',
        createdAt: '2021-11-02T20:56:23.616Z',
        type: 'submissions',
        value: undefined
      }
      props = {
        ...defaultProps,
        condition
      }
      onChange = jest.fn()
      onDelete = jest.fn()
    })

    it('renders conditions for submissions', () => {
      const {getByRole} = render(
        <FilterNavCondition {...props} onChange={onChange} onDelete={onDelete} />
      )
      const button = getByRole('button', {name: 'Condition type'})
      expect(button).toBeInTheDocument()
    })

    it('sets the submissions field if value is present', () => {
      condition.value = 'has-ungraded-submissions'
      const {getByRole} = render(
        <FilterNavCondition {...props} onChange={onChange} onDelete={onDelete} />
      )
      const button: Partial<HTMLButtonElement> = getByRole('button', {name: 'Condition'})
      expect(button?.value).toContain('Has ungraded submissions')
    })

    it('changing value triggers onChange', async () => {
      const {getByRole} = render(
        <FilterNavCondition {...props} onChange={onChange} onDelete={onDelete} />
      )
      userEvent.click(getByRole('button', {name: 'Condition'}))
      userEvent.click(getByRole('option', {name: 'Has ungraded submissions'}))
      expect(onChange).toHaveBeenLastCalledWith(
        expect.objectContaining({
          type: 'submissions',
          value: 'has-ungraded-submissions'
        })
      )
    })
  })

  describe('sections', () => {
    let props, condition, onChange, onDelete
    beforeEach(() => {
      condition = {
        id: '456',
        createdAt: '2021-11-02T20:56:23.616Z',
        type: 'section',
        value: '1'
      }
      props = {
        ...defaultProps,
        condition,
        sections: [
          {id: '1', name: 'Section 1'},
          {id: '2', name: 'Section 2'}
        ]
      }
      onChange = jest.fn()
      onDelete = jest.fn()
    })

    it('sets the sections field if value is present', () => {
      condition.value = '1'
      const {getByRole} = render(
        <FilterNavCondition {...props} onChange={onChange} onDelete={onDelete} />
      )
      const button: Partial<HTMLButtonElement> = getByRole('button', {name: 'Condition'})
      expect(button.value).toContain('Section 1')
    })

    it('changing value triggers onChange', async () => {
      const {getByRole} = render(
        <FilterNavCondition {...props} onChange={onChange} onDelete={onDelete} />
      )
      userEvent.click(getByRole('button', {name: 'Condition'}))
      userEvent.click(getByRole('option', {name: 'Section 1'}))
      expect(onChange).toHaveBeenLastCalledWith(
        expect.objectContaining({
          id: '456',
          type: 'section',
          value: '1'
        })
      )
    })
  })

  describe('grading periods', () => {
    let props, condition, onChange, onDelete
    beforeEach(() => {
      condition = {
        id: '456',
        createdAt: '2021-11-02T20:56:23.616Z',
        type: 'grading-period',
        value: '1'
      }
      props = {
        ...defaultProps,
        condition,
        gradingPeriods: [
          {id: '1', title: 'Grading Period 1', startDate: 1},
          {id: '2', title: 'Grading Period 2', startDate: 2},
          {id: '3', title: 'Grading Period 3', startDate: 3}
        ]
      }
      onChange = jest.fn()
      onDelete = jest.fn()
    })

    it('sets the grading periods field if value is present', () => {
      condition.value = '1'
      const {getByRole} = render(
        <FilterNavCondition {...props} onChange={onChange} onDelete={onDelete} />
      )
      const button: Partial<HTMLButtonElement> = getByRole('button', {name: 'Condition'})
      expect(button.value).toContain('Grading Period 1')
    })

    it('changing value triggers onChange', async () => {
      const {getByRole} = render(
        <FilterNavCondition {...props} onChange={onChange} onDelete={onDelete} />
      )
      userEvent.click(getByRole('button', {name: 'Condition'}))
      userEvent.click(getByRole('option', {name: 'Grading Period 1'}))
      expect(onChange).toHaveBeenLastCalledWith(
        expect.objectContaining({
          id: '456',
          type: 'grading-period',
          value: '1'
        })
      )
    })
  })

  describe('student groups', () => {
    let props, condition, onChange, onDelete
    beforeEach(() => {
      condition = {
        id: '456',
        createdAt: '2021-11-02T20:56:23.616Z',
        type: 'student-group',
        value: '1'
      }
      props = {
        ...defaultProps,
        condition,
        studentGroupCategories: {
          '1': {
            id: '1',
            name: 'Student Group Category 1',
            groups: [
              {id: '1', name: 'Student Group 1'},
              {id: '2', name: 'Student Group 2'}
            ]
          },
          '2': {
            id: '1',
            name: 'Student Group Category 2',
            groups: [
              {id: '3', name: 'Student Group 3'},
              {id: '4', name: 'Student Group 4'}
            ]
          }
        }
      }
      onChange = jest.fn()
      onDelete = jest.fn()
    })

    it('sets the student group field if value is present', () => {
      condition.value = '1'
      const {getByRole} = render(
        <FilterNavCondition {...props} onChange={onChange} onDelete={onDelete} />
      )
      const button: Partial<HTMLButtonElement> = getByRole('button', {name: 'Condition'})
      expect(button.value).toContain('Student Group 1')
    })

    it('changing value triggers onChange', async () => {
      const {getByRole} = render(
        <FilterNavCondition {...props} onChange={onChange} onDelete={onDelete} />
      )
      userEvent.click(getByRole('button', {name: 'Condition'}))
      userEvent.click(getByRole('option', {name: 'Student Group 1'}))
      expect(onChange).toHaveBeenLastCalledWith(
        expect.objectContaining({
          id: '456',
          type: 'student-group',
          value: '1'
        })
      )
    })

    it(`does not allow to create two section conditions`, () => {
      props.conditionsInFilter = [
        {
          id: '459',
          createdAt: '2021-11-02T20:56:23.616Z',
          type: 'section',
          value: 'Fri Dec 05 2021 02:00:00 GMT-0500 (Colombia Standard Time)'
        }
      ]
      const {queryByRole} = render(
        <FilterNavCondition {...props} onChange={onChange} onDelete={onDelete} />
      )
      const select = queryByRole('button', {name: 'Condition type'})
      fireEvent.click(select!)
      const option = queryByRole('option', {name: 'Section'})
      expect(option).not.toBeInTheDocument()
    })

    it(`does not allow to create two student group conditions`, () => {
      props.conditionsInFilter = [
        {
          id: '460',
          createdAt: '2021-11-02T20:56:23.616Z',
          type: 'student-group',
          value: 'Fri Dec 05 2021 02:00:00 GMT-0500 (Colombia Standard Time)'
        }
      ]
      const {queryByRole} = render(
        <FilterNavCondition {...props} onChange={onChange} onDelete={onDelete} />
      )
      const select = queryByRole('button', {name: 'Condition type'})
      fireEvent.click(select!)
      const option = queryByRole('option', {name: 'Student Group'})
      expect(option).not.toBeInTheDocument()
    })
  })
})

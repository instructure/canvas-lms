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
import {render, fireEvent, screen} from '@testing-library/react'
import '@testing-library/jest-dom/extend-expect'

const dateTests = (testType: string, dateFieldName: string) => {
  let props, condition, conditionsInFilter, onChange, onDelete
  beforeEach(() => {
    condition = {
      id: '456',
      createdAt: '2021-11-02T20:56:23.616Z',
      type: testType,
      value: undefined
    }
    conditionsInFilter = []
    props = {
      condition,
      conditionsInFilter,
      modules: [],
      assignmentGroups: [],
      sections: []
    }
    onChange = jest.fn()
    onDelete = jest.fn()
  })

  it('renders a date field', () => {
    const {getByTestId} = render(
      <FilterNavCondition {...props} onChange={onChange} onDelete={onDelete} />
    )
    const dateComponent = getByTestId('date-input')
    expect(dateComponent).toBeInTheDocument()
  })

  it('sets the date field value if the condition value is present', () => {
    condition.value = 'Fri Dec 03 2021 02:00:00 GMT-0500 (Colombia Standard Time)'
    props.condition = condition
    const {getByTestId} = render(
      <FilterNavCondition {...props} onChange={onChange} onDelete={onDelete} />
    )
    const dateComponent = getByTestId('date-input')
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
})

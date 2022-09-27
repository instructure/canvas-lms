/* Copyright (C) 2020 - present Instructure, Inc.
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
import {render, act, fireEvent} from '@testing-library/react'
import {SearchFormComponent as Subject} from '../SearchForm'

function defaultProps() {
  return {
    fetchHistoryStatus: 'started',
    getGradebookHistory: Function.prototype,
    clearSearchOptions: Function.prototype,
    getSearchOptions: Function.prototype,
    getSearchOptionsNextPage: Function.prototype,
    assignments: {
      fetchStatus: 'started',
      items: [],
      nextPage: '',
    },
    graders: {
      fetchStatus: 'started',
      items: [],
      nextPage: '',
    },
    students: {
      fetchStatus: 'started',
      items: [],
      nextPage: '',
    },
  }
}

const fields = ['assignments', 'graders', 'students']

function mountSubject(props = {}) {
  return render(<Subject {...defaultProps()} {...props} />)
}

let liveRegion = null
beforeAll(() => {
  if (!document.getElementById('flash_screenreader_holder')) {
    liveRegion = document.createElement('div')
    liveRegion.id = 'flash_screenreader_holder'
    liveRegion.setAttribute('role', 'alert')
    document.body.appendChild(liveRegion)
  }
})

afterAll(() => {
  if (liveRegion) liveRegion.remove()
})

describe('GradebookHistory::SearchFormComponent', () => {
  beforeEach(() => {
    jest.useFakeTimers()
  })

  it('displays a flash alert on fetch failure', () => {
    const {rerender} = mountSubject()
    let flash = document.getElementById('flashalert_message_holder')
    expect(flash).toBeNull()
    rerender(<Subject {...defaultProps()} fetchHistoryStatus="failure" />)
    flash = document.getElementById('flashalert_message_holder')
    expect(flash).toBeInTheDocument()
  })

  it('properly debounces getSearchOptions calls', () => {
    const getSearchOptions = jest.fn()
    const {container} = mountSubject({getSearchOptions})
    const input = container.querySelector('input#assignments')
    fireEvent.click(input)
    fireEvent.input(input, {target: {id: 'assignments', value: 'onetwo'}})
    expect(getSearchOptions).not.toHaveBeenCalled()
  })

  describe('calls getSearchOptions with correct arguments after more than two letters are typed', () => {
    fields.forEach(field => {
      it(`for ${field}`, () => {
        const getSearchOptions = jest.fn()
        const {container} = mountSubject({getSearchOptions})
        const input = container.querySelector(`input#${field}`)
        fireEvent.click(input)
        fireEvent.input(input, {target: {id: field, value: 'onetwo'}})
        act(() => {
          jest.advanceTimersByTime(500)
        }) // wait for debounce
        expect(getSearchOptions).toHaveBeenCalledWith(field, 'onetwo')
      })
    })
  })

  describe('hits clearSearchOptions after two or fewer letters are typed', () => {
    fields.forEach(field => {
      it(`for ${field}`, () => {
        const clearSearchOptions = jest.fn()
        const {container} = mountSubject({
          clearSearchOptions,
          [field]: {
            fetchStatus: 'success',
            items: [{id: '1', name: `One of the ${field}`}],
            nextPage: '',
          },
        })
        const input = container.querySelector(`input#${field}`)
        fireEvent.click(input)
        fireEvent.input(input, {target: {id: field, value: 'xy'}})
        expect(clearSearchOptions).toHaveBeenCalledWith(field)
      })
    })
  })

  describe('displays correct "not found" message when no search records are returned', () => {
    fields.forEach(field => {
      it(`for ${field}`, () => {
        // slight mismatch between prop name and what's displayed, here...
        const displayField = field === 'assignments' ? 'artifacts' : field
        const {rerender, container, getByText} = mountSubject()
        const results = {
          [field]: {fetchStatus: 'success', items: [], nextPage: ''},
        }
        rerender(<Subject {...defaultProps()} {...results} />)
        const input = container.querySelector(`input#${field}`)
        fireEvent.click(input)
        expect(getByText(`No ${displayField} with that name found`)).toBeInTheDocument()
      })
    })
  })

  it('calls getSearchOptionsNextPage if there are more items to load', () => {
    const getSearchOptionsNextPage = jest.fn()
    const {rerender} = mountSubject({getSearchOptionsNextPage})
    expect(getSearchOptionsNextPage).not.toHaveBeenCalled()
    rerender(
      <Subject
        getSearchOptionsNextPage={getSearchOptionsNextPage}
        {...defaultProps()}
        students={{
          fetchStatus: 'success',
          items: [],
          nextPage: 'https://nextpage.example.com',
        }}
      />
    )
    expect(getSearchOptionsNextPage).toHaveBeenCalledWith(
      'students',
      'https://nextpage.example.com'
    )
  })
})

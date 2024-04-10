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
import {shallow} from 'enzyme'
import {render, screen} from '@testing-library/react'
import {Spinner} from '@instructure/ui-spinner'
import {Table} from '@instructure/ui-table'
import {SearchResultsComponent} from '../SearchResults'

function defaultHistoryItems() {
  return [
    {
      assignment: {
        anonymousGrading: false,
        gradingType: 'points',
        muted: false,
        name: 'Rustic Rubber Duck',
      },
      date: 'May 30, 2017',
      displayAsPoints: true,
      grader: 'Ms. Twillie Jones',
      gradeAfter: '21',
      gradeBefore: '19',
      gradeCurrent: '22',
      id: '123456',
      pointsPossibleBefore: '25',
      pointsPossibleAfter: '25',
      pointsPossibleCurrent: '30',
      student: 'Norval Abbott',
      time: '11:16pm',
      gradedAnonymously: false,
      courseOverrideGrade: false,
    },
  ]
}

function defaultProps() {
  return {
    caption: 'search results caption',
    fetchHistoryStatus: 'success',
    historyItems: defaultHistoryItems(),
    getNextPage() {},
    nextPage: 'example.com',
    requestingResults: false,
  }
}

function mountComponent(customProps = {}) {
  // @ts-ignore
  return shallow(<SearchResultsComponent {...defaultProps()} {...customProps} />)
}

describe('SearchResults', () => {
  test('does not show a Table/Spinner if no historyItems passed', () => {
    const wrapper = mountComponent({historyItems: []})
    expect(wrapper.find(Table).exists()).toBeFalsy()
  })

  test('shows a Table if there are historyItems passed', function () {
    const wrapper = mountComponent(defaultProps())
    expect(wrapper.find(Table).exists()).toBeTruthy()
  })

  test('Table is passed the label and caption props', function () {
    const wrapper = mountComponent(defaultProps())
    const table = wrapper.find(Table)
    expect(table.props().caption).toEqual('search results caption')
  })

  test('Table has column headers in correct order', () => {
    const expectedHeaders = [
      'Date',
      'Anonymous Grading',
      'Student',
      'Grader',
      'Artifact',
      'Before',
      'After',
      'Current',
    ]
    const wrapper = render(<SearchResultsComponent {...defaultProps()} />)
    const headers = [...wrapper.container.querySelectorAll('thead tr th')].map(n => n.textContent)

    expect(headers).toEqual(expectedHeaders)
  })

  test('Table displays the formatted historyItems passed it', () => {
    const items = defaultHistoryItems()
    const props = {...defaultProps(), items}
    const tableBody = render(<SearchResultsComponent {...props} />)
    expect(tableBody.container.querySelectorAll('tbody tr').length).toEqual(items.length)
    tableBody.unmount()
  })

  test('does not show a Spinner if requestingResults false', function () {
    const wrapper = mountComponent(defaultProps())
    expect(wrapper.find(Spinner).exists()).toBeFalsy()
  })

  test('shows a Spinner if requestingResults true', () => {
    const wrapper = mountComponent({requestingResults: true})
    expect(wrapper.find(Spinner).exists()).toBeTruthy()
  })

  test('Table shows text if request was made but no results were found', () => {
    const props = {...defaultProps(), fetchHistoryStatus: 'success', historyItems: []}
    render(<SearchResultsComponent {...props} />)
    const textBox = screen.getByText('No results found.')
    expect(textBox).toBeInTheDocument()
  })

  test('shows text indicating that the end of results was reached', () => {
    const historyItems = defaultHistoryItems()
    const props = {...defaultProps(), nextPage: '', requestingResults: false, historyItems}
    render(<SearchResultsComponent {...props} />)
    const textBox = screen.getByText('No more results to load.')
    expect(textBox).toBeInTheDocument()
  })

  test('loads next page if possible and the first results did not result in a scrollbar', async () => {
    const actualInnerHeight = window.innerHeight
    // fake to test that there's not a vertical scrollbar
    window.innerHeight = document.body.clientHeight + 1
    const historyItems = defaultHistoryItems()
    const props = {...defaultProps(), nextPage: 'example.com', getNextPage: jest.fn()}
    const wrapper = render(<SearchResultsComponent {...props} />)
    wrapper.rerender(<SearchResultsComponent {...props} historyItems={historyItems} />)
    expect(props.getNextPage).toHaveBeenCalledTimes(1)
    window.innerHeight = actualInnerHeight
  })

  test('loads next page on scroll if possible', () => {
    const actualInnerHeight = window.innerHeight
    const props = {
      ...defaultProps(),
      nextPage: 'example.com',
      getNextPage: jest.fn(),
    }
    render(<SearchResultsComponent {...props} />)
    window.innerHeight = document.body.clientHeight - 1
    document.dispatchEvent(new Event('scroll'))
    expect(props.getNextPage).toHaveBeenCalledTimes(1)
    window.innerHeight = actualInnerHeight
  })

  test('loads next page if available on window resize that causes window to not have a scrollbar', () => {
    const historyItems = defaultHistoryItems()
    const props = {
      ...defaultProps(),
      historyItems,
      nextPage: 'example.com',
      getNextPage: jest.fn(),
    }
    render(<SearchResultsComponent {...props} />)
    window.innerHeight = document.body.clientHeight
    window.dispatchEvent(new Event('resize'))
    expect(props.getNextPage).toHaveBeenCalledTimes(1)
  })
})

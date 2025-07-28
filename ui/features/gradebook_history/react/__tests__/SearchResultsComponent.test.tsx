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
import $ from 'jquery'
import {render, screen} from '@testing-library/react'
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

interface SearchResultsComponentProps {
  caption?: string
  fetchHistoryStatus?: string
  historyItems?: Array<{
    assignment: {
      anonymousGrading: boolean
      gradingType: string
      muted: boolean
      name: string
    }
    date: string
    displayAsPoints: boolean
    grader: string
    gradeAfter: string
    gradeBefore: string
    gradeCurrent: string
    id: string
    pointsPossibleBefore: string
    pointsPossibleAfter: string
    pointsPossibleCurrent: string
    student: string
    time: string
    gradedAnonymously: boolean
    courseOverrideGrade: boolean
  }>
  getNextPage?: () => void
  nextPage?: string
  requestingResults?: boolean
}

function renderComponent(customProps: Partial<SearchResultsComponentProps> = {}) {
  return render(<SearchResultsComponent {...defaultProps()} {...customProps} />)
}

describe('SearchResults', () => {
  test('does not show a Table/Spinner if no historyItems passed', () => {
    renderComponent({historyItems: []})
    expect(screen.queryByRole('table')).not.toBeInTheDocument()
  })

  test('shows a Table if there are historyItems passed', function () {
    renderComponent(defaultProps())
    expect(screen.getByRole('table')).toBeInTheDocument()
  })

  test('Table has the correct caption', function () {
    renderComponent(defaultProps())
    expect(screen.getByRole('table', {name: 'search results caption'})).toBeInTheDocument()
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
    expect(tableBody.container.querySelectorAll('tbody tr')).toHaveLength(items.length)
    tableBody.unmount()
  })

  test('does not show a Spinner if requestingResults false', function () {
    renderComponent(defaultProps())
    expect(screen.queryByRole('img', {name: /loading/i})).not.toBeInTheDocument()
  })

  test('shows a Spinner if requestingResults true', () => {
    $.screenReaderFlashMessage = jest.fn()
    renderComponent({requestingResults: true})
    expect(screen.getByRole('img', {name: /loading/i})).toBeInTheDocument()
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

/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import ViolationTable from '../ViolationTable'
import {render, fireEvent} from '@testing-library/react'

describe('Violation Table', () => {
  const VIOLATIONS = [
    {
      uri: 'http://example.com/something.js',
      latest_hit: '2019-11-11T00:00:00.000Z',
      count: 7,
    },
    {
      uri: 'http://clayd.dev/nothing.js',
      latest_hit: '2019-11-12T00:00:00.000Z',
      count: 2,
    },
  ]

  const getProps = overrides => ({
    violations: VIOLATIONS,
    whitelistedDomains: {account: []},
    accountId: '123',
    addDomain: () => {},
    ...overrides,
  })

  it('shows each violation given on a row', async () => {
    const {findAllByText} = render(<ViolationTable {...getProps()} />)

    const results = await findAllByText(
      content => content.startsWith('Add') && content.endsWith('as an allowed domain')
    )
    expect(results.length).toBe(2)
  })
  it('shows the domain name only for each violation', async () => {
    const {findByText} = render(<ViolationTable {...getProps()} />)

    const domainOne = await findByText('example.com')
    const domainTwo = await findByText('clayd.dev')
    expect(domainOne).toBeInTheDocument()
    expect(domainTwo).toBeInTheDocument()
  })
  it('shows the date of the last violation', async () => {
    const {findByText} = render(<ViolationTable {...getProps()} />)

    const dateOne = await findByText('11/11/2019')
    const dateTwo = await findByText('11/12/2019')
    expect(dateOne).toBeInTheDocument()
    expect(dateTwo).toBeInTheDocument()
  })
  it('shows how many attempts a violation has had', async () => {
    const {findByText} = render(<ViolationTable {...getProps()} />)
    const dateOne = await findByText('7')
    const dateTwo = await findByText('2')
    expect(dateOne).toBeInTheDocument()
    expect(dateTwo).toBeInTheDocument()
  })

  it('filters out any violations that currently exist in the allowed domain list', () => {
    const {container, queryAllByText} = render(
      <ViolationTable {...getProps({whitelistedDomains: {account: ['clayd.dev']}})} />
    )
    expect(container.querySelectorAll('th[scope=row]')).toHaveLength(1)
    expect(queryAllByText('clayd.dev')).toHaveLength(0)
  })

  it('shows a info message when there are no violations present', async () => {
    const {findByText} = render(<ViolationTable violations={[]} />)
    expect(await findByText(/No violations/)).toBeInTheDocument()
  })

  describe('adding to whitelist', () => {
    it('calls the addDomain prop when clicking the add button', async () => {
      const fakeAddDomain = jest.fn()
      const {findByText} = render(<ViolationTable {...getProps({addDomain: fakeAddDomain})} />)
      const addButton = await findByText('Add clayd.dev as an allowed domain')
      fireEvent.click(addButton)
      expect(fakeAddDomain).toHaveBeenCalledWith(
        'account',
        '123',
        'clayd.dev',
        expect.any(Function)
      )
    })

    it('shows a flash message after adding a domain', async () => {
      const fakeAddDomain = jest.fn((a, b, c, d) => d())
      const fakeAlert = jest.fn()
      const {findByText} = render(
        <ViolationTable {...getProps({addDomain: fakeAddDomain, showAlert: fakeAlert})} />
      )
      const addButton = await findByText('Add clayd.dev as an allowed domain')
      fireEvent.click(addButton)
      expect(fakeAlert).toHaveBeenCalledWith({
        message: 'Success: You added clayd.dev as an allowed domain.',
        type: 'success',
      })
    })
  })

  describe('sorting', () => {
    const SORT_VIOLATIONS = [
      {
        uri: 'http://example.com/something.js',
        latest_hit: '2019-11-11T00:00:00.000Z',
        count: 5,
      },
      {
        uri: 'http://instructure.com/nothing.js',
        latest_hit: '2019-11-13T00:00:00.000Z',
        count: 3,
      },
      {
        uri: 'http://clayd.dev/nothing.js',
        latest_hit: '2019-11-12T00:00:00.000Z',
        count: 2,
      },
    ]

    it('defaults to sorting descending based on the attempt count', () => {
      const {container} = render(<ViolationTable {...getProps({violations: SORT_VIOLATIONS})} />)
      const rows = Array.from(container.querySelectorAll('th[scope=row]')).map(x => x.textContent)
      expect(rows).toEqual(['example.com', 'instructure.com', 'clayd.dev'])
    })

    it('sorts based on the name when clicking the header (ascending and descending)', async () => {
      const {findByText, container} = render(
        <ViolationTable {...getProps({violations: SORT_VIOLATIONS})} />
      )

      const domainHeader = await findByText('Blocked Domain Name')
      fireEvent.click(domainHeader)

      const rows = Array.from(container.querySelectorAll('th[scope=row]')).map(x => x.textContent)
      expect(rows).toEqual(['clayd.dev', 'example.com', 'instructure.com'])

      fireEvent.click(domainHeader)
      const rowsTwo = Array.from(container.querySelectorAll('th[scope=row]')).map(
        x => x.textContent
      )
      expect(rowsTwo).toEqual(['instructure.com', 'example.com', 'clayd.dev'])
    })

    it('sorts based on the date when clicking the header (ascending and descending)', async () => {
      const {findByText, container} = render(
        <ViolationTable {...getProps({violations: SORT_VIOLATIONS})} />
      )

      const dateHeader = await findByText('Last Attempt')
      fireEvent.click(dateHeader)

      const rows = Array.from(container.querySelectorAll('th[scope=row]')).map(x => x.textContent)
      expect(rows).toEqual(['example.com', 'clayd.dev', 'instructure.com'])

      fireEvent.click(dateHeader)
      const rowsTwo = Array.from(container.querySelectorAll('th[scope=row]')).map(
        x => x.textContent
      )
      expect(rowsTwo).toEqual(['instructure.com', 'clayd.dev', 'example.com'])
    })

    it('sorts based on the attempts when clicking the header (ascending and descending)', async () => {
      const {findByText, container} = render(
        <ViolationTable {...getProps({violations: SORT_VIOLATIONS})} />
      )

      const dateHeader = await findByText('Requested')
      fireEvent.click(dateHeader)

      const rows = Array.from(container.querySelectorAll('th[scope=row]')).map(x => x.textContent)
      expect(rows).toEqual(['clayd.dev', 'instructure.com', 'example.com'])

      fireEvent.click(dateHeader)
      const rowsTwo = Array.from(container.querySelectorAll('th[scope=row]')).map(
        x => x.textContent
      )
      expect(rowsTwo).toEqual(['example.com', 'instructure.com', 'clayd.dev'])
    })
  })
})

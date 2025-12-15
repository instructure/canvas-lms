/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import QuizIPFilters, {type IPFilterSpec, type ElementWithValidator} from '../QuizIPFilters'

const parentId = 'account_settings_quiz_ip_filters'

const filter1: IPFilterSpec = {name: 'one', filter: '1.1.1.1'}
const filter2: IPFilterSpec = {name: 'two', filter: '2.2.2.2'}
const filter3: IPFilterSpec = {name: 'three', filter: '3.3.3.3'}

function renderComponent(filters: IPFilterSpec[]) {
  return render(<QuizIPFilters parentNodeId={parentId} filters={filters} />)
}

let parentDiv: ElementWithValidator
let dataDiv: HTMLDivElement
let explainerSpan: HTMLSpanElement

describe('QuizIPFilters', () => {
  beforeAll(() => {
    dataDiv = document.createElement('div')
    dataDiv.id = 'account_settings_quiz_ip_filters_data'
    document.body.appendChild(dataDiv)

    parentDiv = document.createElement('div')
    parentDiv.id = parentId
    document.body.appendChild(parentDiv)

    explainerSpan = document.createElement('span')
    explainerSpan.id = 'ip_filter_explainer_portal'
    document.body.appendChild(explainerSpan)
  })

  afterAll(() => {
    document.body.removeChild(dataDiv)
    document.body.removeChild(parentDiv as Element)
    document.body.removeChild(explainerSpan)
  })

  it('lets you delete filters', async () => {
    const {getAllByTestId} = renderComponent([filter1, filter2, filter3])
    const deleteFilters = getAllByTestId('delete-ip-filter')
    // delete the second filter
    await userEvent.click(deleteFilters[1])

    // @ts-expect-error
    expect(parentDiv.__performValidation()).toBe(true)
    const hiddenFields = dataDiv.querySelectorAll('input')
    expect(hiddenFields).toHaveLength(2)
    expect(hiddenFields[0].name).toBe('account[ip_filters][one]')
    expect(hiddenFields[0].value).toBe('1.1.1.1')
    expect(hiddenFields[1].name).toBe('account[ip_filters][three]')
    expect(hiddenFields[1].value).toBe('3.3.3.3')
  })

  it('removes illegal square brackets from filter names', async () => {
    const {getByTestId} = renderComponent([])
    const addFilter = getByTestId('add-ip-filter')
    await userEvent.click(addFilter)
    const nameField = getByTestId('ip-filter-name') as HTMLInputElement
    const filterField = getByTestId('ip-filter-filter') as HTMLInputElement

    // Use paste instead of type to avoid timeout issues with complex strings
    await userEvent.click(nameField)
    await userEvent.paste('garcon[cso[uiuc.edu][]')
    await userEvent.click(filterField)
    await userEvent.paste('[not an IP [but let us see]')

    // @ts-expect-error
    expect(parentDiv.__performValidation()).toBe(true)
    const hiddenFields = dataDiv.querySelectorAll('input')
    expect(hiddenFields).toHaveLength(1)
    // brackets in filter names become underscores
    expect(hiddenFields[0].name).toBe('account[ip_filters][garcon_cso_uiuc.edu___]')
    // brackets in filter values should be left alone
    expect(hiddenFields[0].value).toBe('[not an IP [but let us see]')
  })

  it('adds the right form field when no filters are submitted', () => {
    renderComponent([])
    // @ts-expect-error
    expect(parentDiv.__performValidation()).toBe(true)
    const hiddenFields = dataDiv.querySelectorAll('input')
    expect(hiddenFields).toHaveLength(1)
    expect(hiddenFields[0].name).toBe('account[remove_ip_filters]')
    expect(hiddenFields[0].value).toBe('1')
  })
})

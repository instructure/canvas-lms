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
import {render, screen} from '@testing-library/react'
import QuizIPFilters, {type IPFilterSpec, type ElementWithValidator} from '../QuizIPFilters'

const parentId = 'account_settings_quiz_ip_filters'

const filter1: IPFilterSpec = {name: 'one', filter: '1.1.1.1'}
const filter2: IPFilterSpec = {name: 'two', filter: '2.2.2.2'}

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

  it('renders when no filters are given', () => {
    const {getByText} = renderComponent([])
    expect(getByText('No Quiz IP filters have been set')).toBeInTheDocument()
  })

  it('renders filters', () => {
    const {getAllByTestId} = renderComponent([filter1, filter2])
    const names = getAllByTestId('ip-filter-name')
    const filters = getAllByTestId('ip-filter-filter')
    expect(names.map(n => (n as HTMLInputElement).value)).toEqual(['one', 'two'])
    expect(filters.map(n => (n as HTMLInputElement).value)).toEqual(['1.1.1.1', '2.2.2.2'])
  })

  it('shows the explainer tip only when the info icon is focussed', async () => {
    renderComponent([])
    await new Promise(resolve => requestAnimationFrame(resolve)) // wait for InstUI to settle down
    expect(screen.getByText('filters are a way to limit access', {exact: false})).not.toBeVisible()
    screen.getByTestId('ip-filter-help-toggle')?.focus()
    await new Promise(resolve => requestAnimationFrame(resolve)) // wait for InstUI to settle down
    expect(screen.getByText('filters are a way to limit access', {exact: false})).toBeVisible()
  })
})

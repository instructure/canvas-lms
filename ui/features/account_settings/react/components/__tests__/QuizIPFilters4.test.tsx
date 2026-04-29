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
import userEvent from '@testing-library/user-event'
import QuizIPFilters, {type IPFilterSpec, type ElementWithValidator} from '../QuizIPFilters'

const parentId = 'account_settings_quiz_ip_filters'

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

  it('does the right things on a validation error', async () => {
    const {getByTestId} = renderComponent([])
    const addFilter = getByTestId('add-ip-filter')
    await userEvent.click(addFilter)

    const nameField = getByTestId('ip-filter-name')
    const filterField = getByTestId('ip-filter-filter')
    await userEvent.type(nameField, 'empty')

    // do not put anything in the filter field, and try to submit
    // Validator should return false, the errored field should have focus
    // and the error message should be visible
    // @ts-expect-error
    expect(parentDiv.__performValidation()).toBe(false)
    expect(filterField).toHaveFocus()
    expect(screen.getByText('This field is required')).toBeInTheDocument()
  })
})

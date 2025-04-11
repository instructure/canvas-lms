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

  it('adds the validation hook onto the parent div', () => {
    renderComponent([])
    expect(typeof parentDiv!.__performValidation).toBe('function')
  })

  it('adds screenreader text to the Add Filter button', async () => {
    const {getByTestId} = renderComponent([])
    const addFilter = getByTestId('add-ip-filter')
    await new Promise(resolve => requestAnimationFrame(resolve)) // wait for InstUI to settle down
    expect(addFilter.attributes.getNamedItem('aria-label')?.value).toBe('Add a quiz IP filter')
  })

  it('lets you create new filters', async () => {
    const {getByTestId} = renderComponent([])
    const addFilter = getByTestId('add-ip-filter')
    await userEvent.click(addFilter)
    const nameField = getByTestId('ip-filter-name')
    const filterField = getByTestId('ip-filter-filter')
    await userEvent.type(nameField, 'garcon.cso.uiuc.edu')
    await userEvent.type(filterField, '128.174.5.58')

    // trigger validation which will add the hidden fields to the form
    // @ts-expect-error
    expect(parentDiv.__performValidation()).toBe(true)
    const hiddenFields = dataDiv.querySelectorAll('input')
    expect(hiddenFields).toHaveLength(1)
    expect(hiddenFields[0].name).toBe('account[ip_filters][garcon.cso.uiuc.edu]')
    expect(hiddenFields[0].value).toBe('128.174.5.58')
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
    const nameField = getByTestId('ip-filter-name')
    const filterField = getByTestId('ip-filter-filter')
    // open square bracket has to be doubled (see userEvent Keyboard docs)
    await userEvent.type(nameField, 'garcon[[cso[[uiuc.edu][[]')
    await userEvent.type(filterField, '[[not an IP [[but let us see]')
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

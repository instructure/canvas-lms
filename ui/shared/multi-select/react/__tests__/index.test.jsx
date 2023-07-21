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

import CanvasMultiSelect from '../index'
import {fireEvent, render} from '@testing-library/react'
import React from 'react'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'

injectGlobalAlertContainers()

describe('CanvasMultiSelect', () => {
  let props
  let options
  const renderComponent = rerenderFn => {
    const renderFn = rerenderFn || render
    return renderFn(
      <CanvasMultiSelect {...props}>
        {options.map(o => (
          <CanvasMultiSelect.Option id={o.id} key={o.id} value={o.id}>
            {o.text}
          </CanvasMultiSelect.Option>
        ))}
      </CanvasMultiSelect>
    )
  }

  beforeEach(() => {
    props = {
      id: 'veggies-multi-select',
      label: 'Vegetables',
      onChange() {},
      selectedOptionIds: [],
    }

    options = [
      {id: '1', text: 'Cucumber'},
      {id: '2', text: 'Broccoli'},
    ]
  })

  it('shows all options when the menu is clicked', () => {
    const {getByRole} = renderComponent()
    const combobox = getByRole('combobox', {name: 'Vegetables'})
    fireEvent.click(combobox)
    expect(getByRole('option', {name: 'Cucumber'})).toBeInTheDocument()
    expect(getByRole('option', {name: 'Broccoli'})).toBeInTheDocument()
  })

  it('shows options provided in subsequent renders after the first', () => {
    const broccoliOption = options.pop()
    const {rerender, getByRole} = renderComponent()
    options.push(broccoliOption)
    renderComponent(rerender)
    const combobox = getByRole('combobox', {name: 'Vegetables'})
    fireEvent.click(combobox)
    expect(getByRole('option', {name: 'Broccoli'})).toBeInTheDocument()
  })

  it('filters available options when text is input', () => {
    const {getByRole, queryByRole} = renderComponent()
    const combobox = getByRole('combobox', {name: 'Vegetables'})
    fireEvent.input(combobox, {target: {value: 'Broc'}})
    expect(getByRole('option', {name: 'Broccoli'})).toBeInTheDocument()
    expect(queryByRole('option', {name: 'Cucumber'})).not.toBeInTheDocument()
  })

  it('accepts a prop to customize content in the input', () => {
    props.customRenderBeforeInput = () => [<div key="foo">Customized Content</div>]
    const {getByText} = renderComponent()
    expect(getByText('Customized Content')).toBeInTheDocument()
  })

  it('on input, matches from the start of the string by default', () => {
    const {getByRole, queryByRole} = renderComponent()
    const combobox = getByRole('combobox', {name: 'Vegetables'})
    fireEvent.input(combobox, {target: {value: 'Broc'}})
    expect(getByRole('option', {name: 'Broccoli'})).toBeInTheDocument()
    fireEvent.input(combobox, {target: {value: 'occo'}})
    expect(queryByRole('option', {name: 'Broccoli'})).not.toBeInTheDocument()
  })

  it('can be configured to perform custom matching', () => {
    props.customMatcher = (option, _searchString) => option.label === 'Broccoli'
    const {getByRole, queryByRole} = renderComponent()
    const combobox = getByRole('combobox', {name: 'Vegetables'})
    fireEvent.input(combobox, {target: {value: '?'}})
    expect(getByRole('option', {name: 'Broccoli'})).toBeInTheDocument()
    expect(queryByRole('option', {name: 'Cucumber'})).not.toBeInTheDocument()
  })
})

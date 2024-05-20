/* * Copyright (C) 2024 - present Instructure, Inc.
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
import SelectMenu from '../SelectMenu'

describe('SelectMenu', () => {
  let props: any
  let wrapper: any

  function mountComponent() {
    return render(<SelectMenu {...props} />)
  }

  beforeEach(() => {
    const options = [
      {id: '3', name: 'Guy B. Studying', url: '/some/url/3'},
      {id: '14', name: 'Jane Doe', url: '/some/url/14'},
      {id: '18', name: 'John Doe', url: '/some/url/18'},
    ]

    props = {
      defaultValue: '14',
      disabled: false,
      id: 'select-menu',
      label: 'Student',
      onChange() {},
      options,
      textAttribute: 'name',
      valueAttribute: 'id',
    }
  })

  test('initializes showing the option with the default value', () => {
    wrapper = mountComponent()
    expect(wrapper.container.querySelector('#select-menu').value).toBe('Jane Doe')
  })

  test('generates one option per item in the options prop', async () => {
    const user = userEvent.setup()
    wrapper = mountComponent()
    await user.click(wrapper.container.querySelector('#select-menu'))
    const options = screen.getAllByTestId('select-menu-option')
    expect(options.length).toBe(3)
  })

  test('uses the textAttribute prop to determine the text for each option', async () => {
    const user = userEvent.setup()
    props.textAttribute = 'url'
    wrapper = mountComponent()
    await user.click(wrapper.container.querySelector('#select-menu'))
    const options = screen.getAllByTestId('select-menu-option')
    options.forEach((o, i) => {
      expect(o.textContent).toBe(props.options[i].url)
    })
  })

  test('textAttribute can be a number that represents the index of the text attribute', async () => {
    const user = userEvent.setup()
    props.defaultValue = 'due_date'
    props.options = [
      ['Title', 'title'],
      ['Due Date', 'due_date'],
    ]
    props.textAttribute = 0
    props.valueAttribute = 1
    wrapper = mountComponent()
    await user.click(wrapper.container.querySelector('#select-menu'))
    const options = screen.getAllByTestId('select-menu-option')
    options.forEach((o, i) => {
      expect(o.textContent).toBe(props.options[i][0])
    })
  })

  test('uses the valueAttribute prop to determine the value for each option', async () => {
    const user = userEvent.setup()
    props.defaultValue = '/some/url/14'
    props.valueAttribute = 'url'
    wrapper = mountComponent()
    await user.click(wrapper.container.querySelector('#select-menu'))
    const options = screen.getAllByTestId('select-menu-option')
    options.forEach((o, i) => {
      expect(o.getAttribute('value')).toBe(props.options[i].url)
    })
  })

  test('valueAttribute can be a number that represents the index of the value attribute', async () => {
    const user = userEvent.setup()
    props.defaultValue = 'due_date'
    props.options = [
      ['Title', 'title'],
      ['Due Date', 'due_date'],
    ]
    props.textAttribute = 0
    props.valueAttribute = 1
    wrapper = mountComponent()
    await user.click(wrapper.container.querySelector('#select-menu'))
    const options = screen.getAllByTestId('select-menu-option')
    options.forEach((o, i) => {
      expect(o.getAttribute('value')).toBe(props.options[i][1])
    })
  })

  test('is disabled if passed disabled: true', () => {
    props.disabled = true
    wrapper = mountComponent()
    expect(wrapper.container.querySelector('#select-menu').disabled).toBe(true)
  })

  test('calls onChange when the menu is changed', async () => {
    const user = userEvent.setup()
    props.onChange = jest.fn()
    wrapper = mountComponent()
    await user.click(wrapper.container.querySelector('#select-menu'))
    const options = screen.getAllByTestId('select-menu-option')
    await user.click(options[0])
    expect(props.onChange).toHaveBeenCalled()
  })
})

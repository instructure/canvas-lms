/* * Copyright (C) 2017 - present Instructure, Inc.
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
import {mount} from 'enzyme'
import SelectMenu from 'ui/features/grade_summary/react/SelectMenu.js'
import {
  makeSelection,
  selectedValue,
  getSelectMenuOptions,
  isSelectDisabled
} from './SelectMenuHelpers'

QUnit.module('SelectMenu', hooks => {
  let props
  let wrapper

  function mountComponent() {
    return mount(<SelectMenu {...props} />, {attachTo: document.getElementById('fixtures')})
  }

  hooks.beforeEach(() => {
    const options = [
      {id: '3', name: 'Guy B. Studying', url: '/some/url/3'},
      {id: '14', name: 'Jane Doe', url: '/some/url/14'},
      {id: '18', name: 'John Doe', url: '/some/url/18'}
    ]

    props = {
      defaultValue: '14',
      disabled: false,
      id: 'select-menu',
      label: 'Student',
      onChange() {},
      options,
      textAttribute: 'name',
      valueAttribute: 'id'
    }
  })

  hooks.afterEach(() => {
    wrapper.unmount()
  })

  test('initializes showing the option with the default value', () => {
    wrapper = mountComponent()
    strictEqual(selectedValue(wrapper), 'Jane Doe')
  })

  test('generates one option per item in the options prop', () => {
    wrapper = mountComponent()

    strictEqual(getSelectMenuOptions(wrapper).length, 3)
  })

  test('uses the textAttribute prop to determine the text for each option', () => {
    props.textAttribute = 'url'
    wrapper = mountComponent()
    const options = getSelectMenuOptions(wrapper)
    options.forEach((o, i) => {
      strictEqual(o.textContent, props.options[i].url)
    })
  })

  test('textAttribute can be a number that represents the index of the text attribute', () => {
    props.defaultValue = 'due_date'
    props.options = [
      ['Title', 'title'],
      ['Due Date', 'due_date']
    ]
    props.textAttribute = 0
    props.valueAttribute = 1
    wrapper = mountComponent()
    const options = getSelectMenuOptions(wrapper)
    options.forEach((o, i) => {
      strictEqual(o.textContent, props.options[i][0])
    })
  })

  test('uses the valueAttribute prop to determine the value for each option', () => {
    props.defaultValue = '/some/url/14'
    props.valueAttribute = 'url'
    wrapper = mountComponent()
    const options = getSelectMenuOptions(wrapper)
    options.forEach((o, i) => {
      strictEqual(o.getAttribute('value'), props.options[i].url)
    })
  })

  test('valueAttribute can be a number that represents the index of the value attribute', () => {
    props.defaultValue = 'due_date'
    props.options = [
      ['Title', 'title'],
      ['Due Date', 'due_date']
    ]
    props.textAttribute = 0
    props.valueAttribute = 1
    wrapper = mountComponent()
    const options = getSelectMenuOptions(wrapper)
    options.forEach((o, i) => {
      strictEqual(o.getAttribute('value'), props.options[i][1])
    })
  })

  test('is disabled if passed disabled: true', () => {
    props.disabled = true
    wrapper = mountComponent()
    strictEqual(isSelectDisabled(wrapper), true)
  })

  test('calls onChange when the menu is changed', () => {
    props.onChange = sinon.stub()
    wrapper = mountComponent()
    makeSelection(wrapper, undefined, '3')
    strictEqual(props.onChange.callCount, 1)
  })
})

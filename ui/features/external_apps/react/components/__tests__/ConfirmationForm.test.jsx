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
import {mount} from 'enzyme'
import ConfirmationForm from '../ConfirmationForm'

let wrapper

function newProps(overrides) {
  return {
    onCancel: jest.fn(),
    onConfirm: jest.fn(),
    message: 'Are you sure you want to install the tool?',
    confirmLabel: 'Yes, please',
    cancelLabel: 'Nope!',
    ...overrides,
  }
}

function mountSubject(props = newProps()) {
  wrapper = mount(<ConfirmationForm {...props} />)
}

afterEach(() => {
  wrapper.unmount()
})

it('uses the specified cancelLabel', () => {
  mountSubject()
  expect(wrapper.find('Button').first().html()).toContain('Nope!')
})

it('uses the specified confirmLabel', () => {
  mountSubject()
  expect(wrapper.find('Button').at(2).html()).toContain('Yes, please')
})

it('uses the specified message', () => {
  const props = newProps()
  mountSubject(props)
  expect(wrapper.find('Text').first().html()).toContain(props.message)
})

it('calls "onCancel" when cancel button is clicked', () => {
  const props = newProps()
  mountSubject(props)
  wrapper.find('Button').first().simulate('click')
  expect(props.onCancel).toHaveBeenCalled()
})

it('calls "onConfirm" when confirm button is clicked', () => {
  const props = newProps()
  mountSubject(props)
  wrapper.find('Button').at(2).simulate('click')
  expect(props.onConfirm).toHaveBeenCalled()
})

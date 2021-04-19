/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import GraderCountNumberInput from 'ui/features/assignment_edit/react/GraderCountNumberInput.js'

QUnit.module('GraderCountNumberInput', hooks => {
  let props
  let wrapper

  function numberInputContainer() {
    return wrapper.find('.ModeratedGrading__GraderCountInputContainer')
  }

  function numberInput() {
    return numberInputContainer().find('.ModeratedGrading__GraderCountInputContainer input')
  }

  function mountComponent() {
    wrapper = mount(<GraderCountNumberInput {...props} />)
  }

  hooks.beforeEach(() => {
    props = {
      currentGraderCount: null,
      locale: 'en',
      availableGradersCount: 10
    }
  })

  test('renders an input', () => {
    mountComponent()
    strictEqual(numberInput().length, 1)
  })

  test('initializes grader count to currentGraderCount', () => {
    props.currentGraderCount = 6
    mountComponent()
    strictEqual(numberInput().instance().value, '6')
  })

  test('initializes count to 2 if currentGraderCount is not present and availableGradersCount is > 1', () => {
    mountComponent()
    strictEqual(numberInput().instance().value, '2')
  })

  test('initializes count to availableGradersCount if currentGraderCount is not present and availableGradersCount is < 2', () => {
    props.availableGradersCount = 1
    mountComponent()
    strictEqual(numberInput().instance().value, '1')
  })

  test('accepts the entered value if it is a positive, whole number', () => {
    mountComponent()
    numberInput().simulate('change', {target: {value: '5'}})
    strictEqual(numberInput().instance().value, '5')
  })

  test('accepts the entered value if it is the empty string', () => {
    mountComponent()
    numberInput().simulate('change', {target: {value: ''}})
    strictEqual(numberInput().instance().value, '')
  })

  test('ignores the negative sign if a negative number is entered', () => {
    mountComponent()
    numberInput().simulate('change', {target: {value: '-5'}})
    strictEqual(numberInput().instance().value, '5')
  })

  test('ignores the numbers after the decimal if a fractional number is entered', () => {
    mountComponent()
    numberInput().simulate('change', {target: {value: '5.8'}})
    strictEqual(numberInput().instance().value, '5')
  })

  test('ignores the input alltogether if the value entered is not numeric', () => {
    mountComponent()
    numberInput().simulate('change', {target: {value: 'a'}})
    strictEqual(numberInput().instance().value, '2')
  })

  test('shows an error message if the grader count is 0', () => {
    mountComponent()
    numberInput().simulate('change', {target: {value: '0'}})
    ok(
      numberInputContainer()
        .text()
        .includes('Must have at least 1 grader')
    )
  })

  test('shows a message if the grader count is > the max', () => {
    mountComponent()
    numberInput().simulate('change', {target: {value: '11'}})
    ok(
      numberInputContainer()
        .text()
        .includes('There are currently 10 available graders')
    )
  })

  test('shows a message with correct grammar if the grader count is > the max and the max is 1', () => {
    props.availableGradersCount = 1
    mountComponent()
    numberInput().simulate('change', {target: {value: '2'}})
    ok(
      numberInputContainer()
        .text()
        .includes('There is currently 1 available grader')
    )
  })

  test('shows an error message on blur if the grader count is the empty string', () => {
    mountComponent()
    numberInput().simulate('change', {target: {value: ''}})
    numberInput().simulate('blur', {type: 'blur', target: {value: ''}})
    ok(
      numberInputContainer()
        .text()
        .includes('Must have at least 1 grader')
    )
  })

  test('does not pass any validation error messages to the NumberInput if the input is valid', () => {
    mountComponent()
    numberInput().simulate('change', {target: {value: '4'}})
    strictEqual(numberInputContainer().text(), 'Number of graders')
  })
})

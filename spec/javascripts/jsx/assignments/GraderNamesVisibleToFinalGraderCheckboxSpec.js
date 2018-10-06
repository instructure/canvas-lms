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
import GraderNamesVisibleToFinalGraderCheckbox from 'jsx/assignments/GraderNamesVisibleToFinalGraderCheckbox'

QUnit.module('GraderNamesVisibleToFinalGraderCheckbox', hooks => {
  let props
  let wrapper

  hooks.beforeEach(() => {
    props = {checked: false}
  })

  function mountComponent() {
    wrapper = mount(<GraderNamesVisibleToFinalGraderCheckbox {...props} />)
  }

  function checkbox() {
    return wrapper.find('input#assignment_grader_names_visible_to_final_grader')
  }

  function formField() {
    return wrapper.find('input[name="grader_names_visible_to_final_grader"][type="hidden"]').at(0).instance()
  }

  test('renders a checkbox', () => {
    mountComponent()
    strictEqual(checkbox().length, 1)
  })

  test('renders an unchecked checkbox when passed checked: false', () => {
    mountComponent()
    strictEqual(checkbox().at(0).instance().checked, false)
  })

  test('renders a checked checkbox when passed checked: true', () => {
    props.checked = true
    mountComponent()
    strictEqual(checkbox().at(0).instance().checked, true)
  })

  test('sets the value of the form input to "false" when passed checked: false', () => {
    mountComponent()
    strictEqual(formField().value, 'false')
  })

  test('sets the value of the form input to "true" when passed checked: true', () => {
    props.checked = true
    mountComponent()
    strictEqual(formField().value, 'true')
  })

  test('checking the checkbox updates the value of the form input', () => {
    mountComponent()
    checkbox().simulate('change', {target: {checked: true}})
    strictEqual(formField().value, 'true')
  })

  test('unchecking the checkbox updates the value of the form input', () => {
    props.checked = true
    mountComponent()
    checkbox().simulate('change', {target: {checked: false}})
    strictEqual(formField().value, 'false')
  })
})

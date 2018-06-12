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
import ModeratedGradingCheckbox from 'jsx/assignments/ModeratedGradingCheckbox'

QUnit.module('ModeratedGradingCheckbox', hooks => {
  let props
  let wrapper

  hooks.beforeEach(() => {
    props = {
      checked: false,
      gradedSubmissionsExist: false,
      isGroupAssignment: false,
      isPeerReviewAssignment: false,
      onChange: () => {}
    }
  })

  function mountComponent() {
    wrapper = mount(<ModeratedGradingCheckbox {...props} />)
  }

  function checkbox() {
    return wrapper.find('input#assignment_moderated_grading[type="checkbox"]')
  }

  test('renders a Moderated Grading checkbox', () => {
    mountComponent()
    strictEqual(checkbox().length, 1)
  })

  test('renders an unchecked checkbox when passed checked: false', () => {
    mountComponent()
    strictEqual(checkbox().node.checked, false)
  })

  test('renders a checked checkbox when passed checked: true', () => {
    props.checked = true
    mountComponent()
    strictEqual(checkbox().node.checked, true)
  })

  test('enables the checkbox if no graded submissions exist, it is not a peer ' +
  'review assignment, and it is not a group assignment', () => {
    mountComponent()
    strictEqual(checkbox().node.disabled, false)
  })

  test('disables the checkbox if graded submissions exist', () => {
    props.gradedSubmissionsExist = true
    mountComponent()
    strictEqual(checkbox().node.disabled, true)
  })

  test('disables the checkbox if it is a peer review assignment', () => {
    props.isPeerReviewAssignment = true
    mountComponent()
    strictEqual(checkbox().node.disabled, true)
  })

  test('disables the checkbox if it is a group assignment', () => {
    props.isGroupAssignment = true
    mountComponent()
    strictEqual(checkbox().node.disabled, true)
  })

  test('calls onChange when checked', () => {
    props.onChange = sinon.stub()
    mountComponent()
    checkbox().simulate('change')
    strictEqual(props.onChange.callCount, 1)
  })

  test('calls onChange with `true` when being checked', () => {
    props.onChange = sinon.stub()
    mountComponent()
    checkbox().simulate('change')
    strictEqual(props.onChange.getCall(0).args[0], true)
  })

  test('calls onChange with `false` when being unchecked', () => {
    props.checked = true
    props.onChange = sinon.stub()
    mountComponent()
    checkbox().simulate('change')
    strictEqual(props.onChange.getCall(0).args[0], false)
  })
})

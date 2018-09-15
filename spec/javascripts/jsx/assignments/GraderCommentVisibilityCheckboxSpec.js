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
import {mount} from 'old-enzyme-2.x-you-need-to-upgrade-this-spec-to-enzyme-3.x-by-importing-just-enzyme'
import GraderCommentVisibilityCheckbox from 'jsx/assignments/GraderCommentVisibilityCheckbox'

QUnit.module('GraderCommentVisibilityCheckbox', hooks => {
  let props
  let wrapper

  hooks.beforeEach(() => {
    props = {
      checked: false,
      onChange() {}
    }
  })

  function mountComponent() {
    wrapper = mount(<GraderCommentVisibilityCheckbox {...props} />)
  }

  function checkbox() {
    return wrapper.find('input#assignment_grader_comment_visibility')
  }

  function formField() {
    return wrapper.find('input[name="grader_comments_visible_to_graders"][type="hidden"]').node
  }

  test('renders a checkbox', () => {
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

  test('checking the checkbox calls onChange', () => {
    sinon.stub(props, 'onChange')
    mountComponent()
    checkbox().simulate('change', {target: {checked: true}})
    strictEqual(props.onChange.callCount, 1)
    props.onChange.restore()
  })

  test('unchecking the checkbox calls onChange', () => {
    props.checked = true
    sinon.stub(props, 'onChange')
    mountComponent()
    checkbox().simulate('change', {target: {checked: false}})
    strictEqual(props.onChange.callCount, 1)
    props.onChange.restore()
  })
})

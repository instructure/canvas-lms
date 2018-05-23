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
import ModeratedGradingFormFieldGroup from 'jsx/assignments/ModeratedGradingFormFieldGroup'

QUnit.module('ModeratedGradingFormFieldGroup', hooks => {
  let props
  let wrapper

  hooks.beforeEach(() => {
    props = {
      availableModerators: [{name: 'John Doe', id: '923'}, {name: 'Jane Doe', id: '492'}],
      finalGraderID: undefined,
      locale: 'en',
      maxGraderCount: 10,
      moderatedGradingEnabled: true
    }
  })

  function mountComponent() {
    wrapper = mount(<ModeratedGradingFormFieldGroup {...props} />)
  }

  function checkbox() {
    return wrapper.find('input#assignment_moderated_grading[type="checkbox"]')
  }

  function content() {
    return wrapper.find('.ModeratedGrading__Content')
  }

  test('renders a Moderated Grading checkbox', () => {
    mountComponent()
    strictEqual(checkbox().length, 1)
  })

  test('renders an unchecked checkbox for Moderated Grading when passed moderatedGradingEnabled: false', () => {
    props.moderatedGradingEnabled = false
    mountComponent()
    strictEqual(checkbox().node.checked, false)
  })

  test('renders a checked checkbox for Moderated Grading when passed moderatedGradingEnabled: true', () => {
    mountComponent()
    strictEqual(checkbox().node.checked, true)
  })

  test('hides the moderated grading content when passed moderatedGradingEnabled: false', () => {
    props.moderatedGradingEnabled = false
    mountComponent()
    strictEqual(content().length, 0)
  })

  test('shows the moderated grading content when passed moderatedGradingEnabled: true', () => {
    mountComponent()
    strictEqual(content().length, 1)
  })

  test('includes a final grader select menu in the moderated grading content', () => {
    mountComponent()
    const selectMenu = content().find('select[name="final_grader_id"]')
    strictEqual(selectMenu.length, 1)
  })

  test('includes a grader count input in the moderated grading content', () => {
    mountComponent()
    const graderCountInput = content().find('input[name="grader_count"]')
    strictEqual(graderCountInput.length, 1)
  })

  test('hides the moderated grading content when the checkbox is unchecked', () => {
    mountComponent()
    checkbox().simulate('change')
    strictEqual(content().length, 0)
  })

  test('shows the moderated grading content when the checkbox is checked', () => {
    props.moderatedGradingEnabled = false
    mountComponent()
    checkbox().simulate('change')
    strictEqual(content().length, 1)
  })
})

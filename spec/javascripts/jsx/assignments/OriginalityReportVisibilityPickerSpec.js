/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import {shallow} from 'enzyme'
import OriginalityReportVisibilityPicker from 'ui/features/assignment_edit/react/OriginalityReportVisibilityPicker.js'

QUnit.module('OriginalityReportVisibilityPicker')

test('it renders', () => {
  const wrapper = shallow(
    <OriginalityReportVisibilityPicker isEnabled selectedOption="immediate" />
  )
  ok(wrapper.exists())
})

const options = ['immediate', 'after_grading', 'after_due_date', 'never']
options.forEach(option => {
  test(`it renders "${option}" option`, () => {
    const wrapper = shallow(
      <OriginalityReportVisibilityPicker isEnabled selectedOption="immediate" />
    )
    ok(wrapper.find(`option[value='${option}']`).exists())
  })
})

test('it selects the "selectedOption"', () => {
  const wrapper = shallow(
    <OriginalityReportVisibilityPicker isEnabled selectedOption="after_due_date" />
  )
  ok(wrapper.find('#report_visibility_picker_select').prop('value'), 'after_due_date')
})

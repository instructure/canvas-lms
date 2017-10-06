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

import $ from 'jquery'
import React from 'react'
import { mount } from 'enzyme'
import OriginalityReportVisibilityPicker from 'jsx/assignments/OriginalityReportVisibilityPicker'

QUnit.module('OriginalityReportVisibilityPicker', {
  setup () {}
});

test('it renders', () => {
  const wrapper = mount(
    <OriginalityReportVisibilityPicker
      isEnabled={true}
      selectedOption='immediate'
   />
  );
  ok(wrapper.exists());
});

test('it renders "immediate" option', () => {
  const wrapper = mount(
    <OriginalityReportVisibilityPicker
      isEnabled={true}
      selectedOption='immediate'
   />
  );
  ok(wrapper.find("option[value='immediate']"));
});

test('it renders "after_grading" option', () => {
  const wrapper = mount(
    <OriginalityReportVisibilityPicker
      isEnabled={true}
      selectedOption='immediate'
   />
  );
  ok(wrapper.find("option[value='after_grading']"));
});

test('it renders "after_due_date" option', () => {
  const wrapper = mount(
    <OriginalityReportVisibilityPicker
      isEnabled={true}
      selectedOption='immediate'
   />
  );
  ok(wrapper.find("option[value='after_due_date']"));
});

test('it renders "never" option', () => {
  const wrapper = mount(
    <OriginalityReportVisibilityPicker
      isEnabled={true}
      selectedOption='immediate'
   />
  );
  ok(wrapper.find("option[value='never']"));
});

test('it selects the "selectedOption"', () => {
  const wrapper = mount(
    <OriginalityReportVisibilityPicker
      isEnabled={true}
      selectedOption='after_due_date'
   />
  );
  ok(wrapper.find('#report_visibility_picker_select').node.value, 'after_due_date')
});

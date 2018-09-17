/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import TestUtils from 'react-addons-test-utils'
import {mount} from 'enzyme'
import ContextSelector from 'jsx/calendar/scheduler/components/appointment_groups/ContextSelector'

let props

QUnit.module('ContextSelector', {
  setup() {
    props = {
      contexts: [],
      appointmentGroup: {}
    }
  },
  teardown() {
    props = null
  }
})

test('renders the ContextSelector component', () => {
  const component = TestUtils.renderIntoDocument(<ContextSelector {...props} />)
  const contextSelector = TestUtils.findRenderedDOMComponentWithClass(component, 'ContextSelector')
  ok(contextSelector)
})

test('renders the ContextSelector dropdown', () => {
  const component = TestUtils.renderIntoDocument(<ContextSelector {...props} />)
  const contextSelector = TestUtils.findRenderedDOMComponentWithClass(component, 'ContextSelector')
  TestUtils.Simulate.click(contextSelector.childNodes[0])
  const contextSelectorDropdown = TestUtils.findRenderedDOMComponentWithClass(
    component,
    'ContextSelector__Dropdown'
  )
  ok(contextSelectorDropdown)
})
test('renders a course in the ContextSelector dropdown', () => {
  props.contexts = [
    {
      id: '1',
      name: 'testcourse',
      asset_string: 'course_1',
      sections: [
        {
          id: '1',
          asset_string: 'course_section_1'
        }
      ]
    }
  ]
  props.appointmentGroup = {context_codes: ['course_1', 'course_section_1']}
  const component = TestUtils.renderIntoDocument(<ContextSelector {...props} />)
  const contextSelector = TestUtils.findRenderedDOMComponentWithClass(component, 'ContextSelector')
  TestUtils.Simulate.click(contextSelector.childNodes[0])
  const contextDropdown = TestUtils.findRenderedDOMComponentWithClass(component, 'CourseListItem')
  ok(contextDropdown)
})

test('renders a course section in the ContextSelector dropdown', () => {
  props.contexts = [
    {
      id: '1',
      name: 'testcourse',
      asset_string: 'course_1',
      sections: [
        {
          id: '1',
          asset_string: 'course_section_1'
        }
      ]
    }
  ]
  props.contexts = [
    {
      id: '1',
      name: 'testcourse',
      asset_string: 'course_1',
      sections: [
        {
          id: '1',
          asset_string: 'course_section_1'
        }
      ]
    }
  ]
  props.appointmentGroup = {context_codes: ['course_1', 'course_section_1']}
  const component = TestUtils.renderIntoDocument(<ContextSelector {...props} />)
  const contextSelector = TestUtils.findRenderedDOMComponentWithClass(component, 'ContextSelector')
  TestUtils.Simulate.click(contextSelector.childNodes[0])
  const sectionDropdown = TestUtils.findRenderedDOMComponentWithClass(component, 'sectionItem')
  ok(sectionDropdown)
})

test('handleDoneClick properly sets state', () => {
  props.contexts = [
    {
      id: '1',
      name: 'testcourse',
      asset_string: 'course_1',
      sections: [
        {
          id: '1',
          asset_string: 'course_section_1'
        }
      ]
    }
  ]
  props.contexts = [
    {
      id: '1',
      name: 'testcourse',
      asset_string: 'course_1',
      sections: [
        {
          id: '1',
          asset_string: 'course_section_1'
        }
      ]
    }
  ]
  props.appointmentGroup = {context_codes: ['course_1', 'course_section_1']}
  const component = TestUtils.renderIntoDocument(<ContextSelector {...props} />)
  const contextSelector = TestUtils.findRenderedDOMComponentWithClass(component, 'ContextSelector')
  TestUtils.Simulate.click(contextSelector.childNodes[0])
  const contextSelectorDropdown = TestUtils.findRenderedDOMComponentWithClass(
    component,
    'ContextSelector__Dropdown'
  )
  ok(contextSelectorDropdown)
  component.handleDoneClick({preventDefault: () => {}})
  ok(!component.state.showDropdown)
})

test('toggleCourse toggles correct courses', () => {
  props.contexts = [
    {
      id: '1',
      name: 'testcourse',
      asset_string: 'course_1',
      sections: [
        {
          id: '1',
          asset_string: 'course_section_1'
        }
      ]
    }
  ]
  props.appointmentGroup = {context_codes: ['course_1', 'course_section_1']}
  const component = TestUtils.renderIntoDocument(<ContextSelector {...props} />)
  ok(!component.contextCheckboxes.course_1.checked)
  TestUtils.Simulate.change(component.contextCheckboxes.course_1, {target: {checked: true}})
  ok(component.contextCheckboxes.course_1.checked)
  TestUtils.Simulate.change(component.contextCheckboxes.course_1, {target: {checked: false}})
  ok(!component.contextCheckboxes.course_1.checked)
})

test('toggleCourse toggles section correctly', () => {
  props.contexts = [
    {
      id: '1',
      name: 'testcourse',
      asset_string: 'course_1',
      sections: [
        {
          id: '1',
          asset_string: 'course_section_1'
        }
      ]
    }
  ]
  props.appointmentGroup = {context_codes: ['course_1', 'course_section_1']}
  const component = TestUtils.renderIntoDocument(<ContextSelector {...props} />)
  ok(!component.contextCheckboxes.course_1.checked)
  TestUtils.Simulate.change(component.contextCheckboxes.course_1, {target: {checked: true}})
  ok(component.contextCheckboxes.course_1.checked)
  ok(component.sectionsCheckboxes.course_section_1.checked)
  TestUtils.Simulate.change(component.contextCheckboxes.course_1, {target: {checked: true}})
  ok(!component.sectionsCheckboxes.course_section_1.checked)
  ok(!component.contextCheckboxes.course_1.checked)
})

test('toggle section when course is selected', () => {
  props.contexts = [
    {
      id: '1',
      name: 'testcourse',
      asset_string: 'course_1',
      sections: [
        {
          id: '1',
          asset_string: 'course_section_1'
        },
        {
          id: '2',
          asset_string: 'course_section_2'
        }
      ]
    }
  ]
  props.appointmentGroup = {context_codes: ['course_1', 'course_section_1', 'course_section_2']}
  const component = TestUtils.renderIntoDocument(<ContextSelector {...props} />)
  ok(!component.contextCheckboxes.course_1.checked)
  TestUtils.Simulate.change(component.contextCheckboxes.course_1, {target: {checked: true}})
  ok(component.contextCheckboxes.course_1.checked)
  ok(component.sectionsCheckboxes.course_section_1.checked)
  TestUtils.Simulate.change(component.sectionsCheckboxes.course_section_1, {
    target: {checked: false}
  })
  ok(!component.sectionsCheckboxes.course_section_1.checked)
  ok(component.contextCheckboxes.course_1.checked)
})

test('parent course is selected when sub sections are selected', () => {
  props.contexts = [
    {
      id: '1',
      name: 'testcourse',
      asset_string: 'course_1',
      sections: [
        {
          id: '1',
          asset_string: 'course_section_1'
        },
        {
          id: '2',
          asset_string: 'course_section_2'
        }
      ]
    }
  ]
  props.appointmentGroup = {context_codes: ['course_1', 'course_section_1', 'course_section_2']}
  const component = TestUtils.renderIntoDocument(<ContextSelector {...props} />)
  ok(!component.sectionsCheckboxes.course_section_2.checked)
  ok(!component.sectionsCheckboxes.course_section_2.checked)
  TestUtils.Simulate.change(component.sectionsCheckboxes.course_section_1, {
    target: {checked: true}
  })
  TestUtils.Simulate.change(component.sectionsCheckboxes.course_section_2, {
    target: {checked: true}
  })
  ok(component.sectionsCheckboxes.course_section_2.checked)
  ok(component.sectionsCheckboxes.course_section_2.checked)
  ok(component.contextCheckboxes.course_1.checked)
})

test('toggleSections toggles correct section', () => {
  props.contexts = [
    {
      id: '1',
      name: 'testcourse',
      asset_string: 'course_1',
      sections: [
        {
          id: '1',
          asset_string: 'course_section_1'
        }
      ]
    }
  ]
  props.appointmentGroup = {context_codes: ['course_1', 'course_section_1']}
  const component = TestUtils.renderIntoDocument(<ContextSelector {...props} />)
  ok(!component.sectionsCheckboxes.course_section_1.checked)
  TestUtils.Simulate.change(component.sectionsCheckboxes.course_section_1, {
    target: {checked: true}
  })
  ok(component.sectionsCheckboxes.course_section_1.checked)
  TestUtils.Simulate.change(component.sectionsCheckboxes.course_section_1, {
    target: {checked: false}
  })
  ok(!component.sectionsCheckboxes.course_section_1.checked)
})

test('toggle course expanded', () => {
  props.contexts = [
    {
      id: '1',
      name: 'testcourse',
      asset_string: 'course_1',
      sections: [
        {
          id: '1',
          asset_string: 'course_section_1'
        }
      ]
    }
  ]
  props.appointmentGroup = {context_codes: ['course_1', 'course_section_1']}
  const wrapper = mount(<ContextSelector {...props} />)
  equal(wrapper.find('.CourseListItem svg').prop('name'), 'IconMiniArrowEnd')

  wrapper.find('.CourseListItem Button').simulate('click')
  equal(wrapper.find('.CourseListItem svg').prop('name'), 'IconMiniArrowDown')
})

test('renders button text correctly on already selected contexts', () => {
  props.contexts = [
    {
      id: '1',
      name: 'testcourse',
      asset_string: 'course_1',
      sections: [
        {
          id: '1',
          asset_string: 'course_section_1'
        }
      ]
    }
  ]
  props.contexts = [
    {
      id: '1',
      name: 'testcourse',
      asset_string: 'course_1',
      sections: [
        {
          id: '1',
          asset_string: 'course_section_1'
        }
      ]
    }
  ]
  props.appointmentGroup = {context_codes: ['course_1', 'course_section_1']}
  const component = TestUtils.renderIntoDocument(<ContextSelector {...props} />)
  const contextSelector = TestUtils.findRenderedDOMComponentWithClass(component, 'ContextSelector')
  ok(contextSelector.childNodes[0].textContent === 'Select Calendars')
  component.componentWillReceiveProps(props)
  ok(contextSelector.childNodes[0].textContent === 'testcourse and 1 other')
})

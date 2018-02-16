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
import TestUtils from 'react-addons-test-utils'
import moxios from 'moxios'
import $ from 'jquery'
import CoursesGroupsAutocomplete from 'jsx/shared/components/CoursesGroupsAutocomplete'

QUnit.module('Course Group Filter', function(hooks) {
  hooks.beforeEach(function() {
    moxios.install()
  })

  hooks.afterEach(function() {
    moxios.uninstall()
  })

  const defaultProps = {
    placeholder: 'This is the default placeholder',
    onChange: (_, e) => e,
    initialSelectedOption: null
  }

  function getCourseUrl(numToFetch) {
    const courseUrlBase = '/api/v1/courses/?'
    const params = {
      state: ['unpublished', 'available', 'completed'],
      include: ['term'],
      enrollment_state: 'active',
      per_page: numToFetch
    }
    return `${courseUrlBase}${$.param(params)}`
  }

  function setUpRequests(numToFetch = 100) {
    const courses = [{id: '1', name: 'Course 1'}, {id: '2', name: 'Course 2'}]
    const groups = [
      {id: '1', name: 'Group 1'},
      {id: '2', name: 'Group 2'},
      {id: '3', name: 'Group 3'}
    ]
    moxios.stubRequest(getCourseUrl(numToFetch), {
      status: 200,
      response: courses
    })
    moxios.stubRequest('/api/v1/users/self/groups', {
      status: 200,
      response: groups
    })
  }

  test('loads proper entites with default props', assert => {
    const done = assert.async()
    setUpRequests()
    // console.log({...defaultProps, selectedOption: 2})
    const component = TestUtils.renderIntoDocument(<CoursesGroupsAutocomplete {...defaultProps} />)
    moxios.wait(() => {
      strictEqual(component.state.courseOptions.length, 2)
      strictEqual(component.state.groupOptions.length, 3)
      for (let i = 0; i < 2; i++) {
        strictEqual(component.state.courseOptions[i].value, `course_${i + 1}`)
        strictEqual(component.state.courseOptions[i].label, `Course ${i + 1}`)
      }
      for (let i = 0; i < 3; ++i) {
        strictEqual(component.state.groupOptions[i].value, `group_${i + 1}`)
        strictEqual(component.state.groupOptions[i].label, `Group ${i + 1}`)
      }
      strictEqual(component.props.placeholder, 'This is the default placeholder')
      strictEqual(component.state.selectedOption, "")
      done()
    })
  })

  test('respects preselected course if valid', assert => {
    const done = assert.async()
    setUpRequests()
    const newProps = {...defaultProps, initialSelectedOption: {entityType: 'course', entityId: 1}}
    const component = TestUtils.renderIntoDocument(<CoursesGroupsAutocomplete {...newProps} />)
    moxios.wait(() => {
      strictEqual(component.state.selectedOption.value, 'course_1')
      strictEqual(component.state.selectedOption.label, 'Course 1')
      done()
    })
  })

  test('clears choice if invalid', assert => {
    const done = assert.async()
    setUpRequests()
    const newProps = {...defaultProps, initialSelectedOption: {entityType: 'course', entityId: 1000}}
    const component = TestUtils.renderIntoDocument(<CoursesGroupsAutocomplete {...newProps} />)
    moxios.wait(() => {
      strictEqual(component.state.selectedOption, "")
      done()
    })
  })
})

/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import ReactDOM from 'react-dom'
import {Simulate, SimulateNative} from 'react-addons-test-utils'
import DueDateRow from 'jsx/due_dates/DueDateRow'
import fakeENV from 'helpers/fakeENV'

QUnit.module('DueDateRow with empty props and canDelete true', {
  setup() {
    fakeENV.setup()
    ENV.context_asset_string = 'course_1'
    const props = {
      overrides: [],
      sections: {},
      students: {},
      dates: {},
      groups: {},
      canDelete: true,
      rowKey: 'nullnullnull',
      validDropdownOptions: [],
      currentlySearching: false,
      allStudentsFetched: true,
      handleDelete() {},
      defaultSectionNamer() {},
      handleTokenAdd() {},
      handleTokenRemove() {},
      replaceDate() {},
      inputsDisabled: false
    }
    const DueDateRowElement = <DueDateRow {...props} />
    this.dueDateRow = ReactDOM.render(DueDateRowElement, $('<div>').appendTo('body')[0])
  },
  teardown() {
    fakeENV.teardown()
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this.dueDateRow).parentNode)
  }
})

test('renders', function() {
  ok(this.dueDateRow.isMounted())
})

test('returns a remove link if canDelete', function() {
  ok(this.dueDateRow.removeLinkIfNeeded())
})

QUnit.module('DueDateRow with realistic props and canDelete false', {
  setup() {
    fakeENV.setup()
    ENV.context_asset_string = 'course_1'
    const props = {
      overrides: [
        {
          get(attr) {
            return {course_section_id: 1}[attr]
          }
        },
        {
          get(attr) {
            return {course_section_id: 2}[attr]
          }
        },
        {
          get(attr) {
            return {
              student_ids: [1, 2, 3]
            }[attr]
          }
        },
        {
          get(attr) {
            return {group_id: 2}[attr]
          }
        }
      ],
      sections: {2: {name: 'section name'}},
      students: {2: {name: 'student name'}},
      groups: {2: {name: 'group name'}},
      dates: {},
      canDelete: false,
      rowKey: 'nullnullnull',
      validDropdownOptions: [],
      currentlySearching: false,
      allStudentsFetched: true,
      handleDelete() {},
      defaultSectionNamer() {},
      handleTokenAdd() {},
      handleTokenRemove() {},
      replaceDate() {},
      inputsDisabled: false
    }
    const DueDateRowElement = <DueDateRow {...props} />
    this.dueDateRow = ReactDOM.render(DueDateRowElement, $('<div>').appendTo('body')[0])
  },
  teardown() {
    fakeENV.teardown()
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this.dueDateRow).parentNode)
  }
})

test('renders', function() {
  ok(this.dueDateRow.isMounted())
})

test('does not return remove link if not canDelete', function() {
  ok(!this.dueDateRow.removeLinkIfNeeded())
})

test('tokenizing ADHOC overrides works', function() {
  const tokens = this.dueDateRow.tokenizedOverrides()
  equal(6, tokens.length)
  equal(3, tokens.filter(t => t.type === 'student').length)
})

test('tokenizing section overrides works', function() {
  const tokens = this.dueDateRow.tokenizedOverrides()
  equal(6, tokens.length)
  equal(2, tokens.filter(t => t.type === 'section').length)
})

test('tokenizing group overrides works', function() {
  const tokens = this.dueDateRow.tokenizedOverrides()
  equal(6, tokens.length)
  equal(1, tokens.filter(t => t.type === 'group').length)
})

test('section tokens are given their proper name if loaded', function() {
  const tokens = this.dueDateRow.tokenizedOverrides()
  const token = tokens.find(t => t.name === 'section name')
  ok(!!token)
})

test('student tokens are their proper name if loaded', function() {
  const tokens = this.dueDateRow.tokenizedOverrides()
  const token = tokens.find(t => t.name === 'student name')
  ok(!!token)
})

test('group tokens are their proper name if loaded', function() {
  const tokens = this.dueDateRow.tokenizedOverrides()
  const token = tokens.find(t => t.name === 'group name')
  ok(!!token)
})

test('student tokens are given the name "Loading..." if they havent loaded', function() {
  const tokens = this.dueDateRow.tokenizedOverrides()
  const token = tokens.find(t => t.name === 'Loading...')
  ok(!!token)
})

QUnit.module('DueDateRow with empty props and inputsDisabled true', {
  setup() {
    fakeENV.setup()
    ENV.context_asset_string = 'course_1'
    const props = {
      overrides: [],
      sections: {},
      students: {},
      dates: {},
      groups: {},
      canDelete: true,
      rowKey: 'nullnullnull',
      validDropdownOptions: [],
      currentlySearching: false,
      allStudentsFetched: true,
      handleDelete() {},
      defaultSectionNamer() {},
      handleTokenAdd() {},
      handleTokenRemove() {},
      replaceDate() {},
      inputsDisabled: true
    }
    const DueDateRowElement = <DueDateRow {...props} />
    this.dueDateRow = ReactDOM.render(DueDateRowElement, $('<div>').appendTo('body')[0])
  },
  teardown() {
    fakeENV.teardown()
    ReactDOM.unmountComponentAtNode(ReactDOM.findDOMNode(this.dueDateRow).parentNode)
  }
})

test('does not return a remove link', function() {
  notOk(this.dueDateRow.removeLinkIfNeeded())
})

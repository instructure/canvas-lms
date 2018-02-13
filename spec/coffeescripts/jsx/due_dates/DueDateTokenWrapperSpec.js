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

import React from 'react'
import ReactDOM from 'react-dom'
import {Simulate, SimulateNative} from 'react-addons-test-utils'
import DueDateTokenWrapper from 'jsx/due_dates/DueDateTokenWrapper'
import OverrideStudentStore from 'jsx/due_dates/OverrideStudentStore'
import fakeENV from 'helpers/fakeENV'

QUnit.module('DueDateTokenWrapper', {
  setup() {
    let context_asset_string
    fakeENV.setup((context_asset_string = 'course_1'))
    this.clock = sinon.useFakeTimers()
    this.props = {
      tokens: [
        {id: '1', name: 'Atilla', student_id: '3', type: 'student'},
        {id: '2', name: 'Huns', course_section_id: '4', type: 'section'},
        {id: '3', name: 'Reading Group 3', group_id: '3', type: 'group'}
      ],
      potentialOptions: [
        {course_section_id: '1', name: 'Patricians'},
        {id: '1', name: 'Seneca The Elder'},
        {id: '2', name: 'Agrippa'},
        {id: '3', name: 'Publius'},
        {id: '4', name: 'Scipio'},
        {id: '5', name: 'Baz'},
        {course_section_id: '2', name: 'Plebs | [ $'}, // named strangely to test regex
        {course_section_id: '3', name: 'Foo'},
        {course_section_id: '4', name: 'Bar'},
        {course_section_id: '5', name: 'Baz'},
        {course_section_id: '6', name: 'Qux'},
        {group_id: '1', name: 'Reading Group One'},
        {group_id: '2', name: 'Reading Group Two'},
        {noop_id: '1', name: 'Mastery Paths'}
      ],
      handleTokenAdd() {},
      handleTokenRemove() {},
      defaultSectionNamer() {},
      allStudentsFetched: false,
      currentlySearching: false,
      rowKey: 'nullnullnull',
      disabled: false
    }
    this.mountPoint = $('<div>').appendTo('body')[0]
    const DueDateTokenWrapperElement = <DueDateTokenWrapper {...this.props} />
    this.DueDateTokenWrapper = ReactDOM.render(DueDateTokenWrapperElement, this.mountPoint)
    this.TokenInput = this.DueDateTokenWrapper.refs.TokenInput
  },
  teardown() {
    this.clock.restore()
    ReactDOM.unmountComponentAtNode(this.mountPoint)
    fakeENV.teardown()
  }
})

test('renders', function() {
  ok(this.DueDateTokenWrapper.isMounted())
})

test('renders a TokenInput', function() {
  ok(this.TokenInput.isMounted())
})

test('call to fetchStudents on input changes', function() {
  const fetch = this.stub(this.DueDateTokenWrapper, 'safeFetchStudents')
  this.DueDateTokenWrapper.handleInput('to')
  equal(fetch.callCount, 1)
  this.DueDateTokenWrapper.handleInput('tre')
  equal(fetch.callCount, 2)
})

test('if a user types handleInput filters the options', function() {
  // having debouncing enabled for fetching makes tests hard to contend with.
  this.DueDateTokenWrapper.removeTimingSafeties()

  // 1 prompt, 3 sections, 4 students, 2 groups, 3 headers, 1 Noop = 14
  equal(this.DueDateTokenWrapper.optionsForMenu().length, 14)
  this.DueDateTokenWrapper.handleInput('scipio')

  // 0 sections, 1 student, 1 header = 2
  equal(this.DueDateTokenWrapper.optionsForMenu().length, 2)
})

test('menu options are grouped by type', function() {
  equal(this.DueDateTokenWrapper.optionsForMenu()[1].props.value, 'course_section')
  equal(this.DueDateTokenWrapper.optionsForMenu()[2].props.value, 'Patricians')
  equal(this.DueDateTokenWrapper.optionsForMenu()[5].props.value, 'group')
  equal(this.DueDateTokenWrapper.optionsForMenu()[6].props.value, 'Reading Group One')
  equal(this.DueDateTokenWrapper.optionsForMenu()[8].props.value, 'student')
  equal(this.DueDateTokenWrapper.optionsForMenu()[9].props.value, 'Seneca The Elder')
})

test('handleTokenAdd is called when a token is added', function() {
  const addProp = this.stub(this.props, 'handleTokenAdd')
  const DueDateTokenWrapperElement = <DueDateTokenWrapper {...this.props} />
  this.DueDateTokenWrapper = ReactDOM.render(DueDateTokenWrapperElement, this.mountPoint)
  this.DueDateTokenWrapper.handleTokenAdd('sene')
  ok(addProp.calledOnce)
  addProp.restore()
})

test('handleTokenRemove is called when a token is removed', function() {
  const removeProp = this.stub(this.props, 'handleTokenRemove')
  const DueDateTokenWrapperElement = <DueDateTokenWrapper {...this.props} />
  this.DueDateTokenWrapper = ReactDOM.render(DueDateTokenWrapperElement, this.mountPoint)
  this.DueDateTokenWrapper.handleTokenRemove('sene')
  ok(removeProp.calledOnce)
  removeProp.restore()
})

test('findMatchingOption can match a string with a token', function() {
  let foundToken = this.DueDateTokenWrapper.findMatchingOption('sci')
  equal(foundToken.name, 'Scipio')
  foundToken = this.DueDateTokenWrapper.findMatchingOption('pub')
  equal(foundToken.name, 'Publius')
})

test('findMatchingOption can handle strings with weird characters', function() {
  const foundToken = this.DueDateTokenWrapper.findMatchingOption('Plebs | [')
  equal(foundToken.name, 'Plebs | [ $')
})

test('findMatchingOption can match characters in the middle of a string', function() {
  const foundToken = this.DueDateTokenWrapper.findMatchingOption('The Elder')
  equal(foundToken.name, 'Seneca The Elder')
})

test('findMatchingOption can match tokens by properties', function() {
  const fakeOption = {
    props: {
      set_props: {
        name: 'Baz',
        course_section_id: '5'
      }
    }
  }
  const foundToken = this.DueDateTokenWrapper.findMatchingOption('Baz', fakeOption)
  equal(foundToken.course_section_id, '5')
})

test('hidingValidMatches updates as matching tag number changes', function() {
  ok(this.DueDateTokenWrapper.hidingValidMatches())
  this.DueDateTokenWrapper.handleInput('scipio')
  ok(!this.DueDateTokenWrapper.hidingValidMatches())
})

test('overrideTokenAriaLabel method', function() {
  equal(
    this.DueDateTokenWrapper.overrideTokenAriaLabel('group X'),
    'Currently assigned to group X, click to remove'
  )
})

QUnit.module('disabled DueDateTokenWrapper', {
  setup() {
    let context_asset_string
    fakeENV.setup((context_asset_string = 'course_1'))
    const props = {
      tokens: [{id: '1', name: 'Atilla', student_id: '3', type: 'student'}],
      potentialOptions: [{course_section_id: '1', name: 'Patricians'}],
      handleTokenAdd() {},
      handleTokenRemove() {},
      defaultSectionNamer() {},
      allStudentsFetched: false,
      currentlySearching: false,
      rowKey: 'wat',
      disabled: true
    }
    this.mountPoint = $('<div>').appendTo('body')[0]
    const DueDateTokenWrapperElement = <DueDateTokenWrapper {...props} />
    this.DueDateTokenWrapper = ReactDOM.render(DueDateTokenWrapperElement, this.mountPoint)
  },
  teardown() {
    ReactDOM.unmountComponentAtNode(this.mountPoint)
    fakeENV.teardown()
  }
})

test('renders a readonly token input', function() {
  ok(this.DueDateTokenWrapper.refs.DisabledTokenInput)
})

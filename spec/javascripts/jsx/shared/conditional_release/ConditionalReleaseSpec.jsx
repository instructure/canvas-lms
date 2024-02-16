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

import ReactDOM from 'react-dom'
import TestUtils from 'react-dom/test-utils'
import $ from 'jquery'
import 'jquery-migrate'
import ConditionalRelease from '@canvas/conditional-release-editor'

let editor = null
class ConditionalReleaseEditor {
  constructor(env) {
    editor = {
      attach: sinon.stub(),
      updateAssignment: sinon.stub(),
      saveRule: sinon.stub(),
      getErrors: sinon.stub(),
      focusOnError: sinon.stub(),
      env,
    }
    return editor
  }
}
window.conditional_release_module = {ConditionalReleaseEditor}

let component = null
const createComponent = submitCallback => {
  component = TestUtils.renderIntoDocument(
    <ConditionalRelease.Editor env={assignmentEnv} type="foo" />
  )
  component.createNativeEditor()
}

const makePromise = () => {
  const promise = {}
  promise.then = sinon.stub().returns(promise)
  promise.catch = sinon.stub().returns(promise)
  return promise
}

let ajax = null
const assignmentEnv = {assignment: {id: 1}, course_id: 1}
const noAssignmentEnv = {edit_rule_url: 'about:blank'}
const assignmentNoIdEnv = {assignment: {foo: 'bar'}, course_id: 1}

QUnit.module('Conditional Release component', {
  setup: () => {
    ajax = sinon.stub($, 'ajax')
    createComponent()
  },

  teardown: () => {
    if (component) {
      const componentNode = ReactDOM.findDOMNode(component)
      if (componentNode) {
        ReactDOM.unmountComponentAtNode(componentNode.parentNode)
      }
    }
    component = null
    editor = null
    ajax.restore()
  },
})

test('it creates a cyoe editor', () => {
  ok(editor.attach.calledOnce)
})

test('it forwards focusOnError', () => {
  component.focusOnError()
  ok(editor.focusOnError.calledOnce)
})

test('it transforms validations', () => {
  editor.getErrors.returns([
    {index: 0, error: 'foo bar'},
    {index: 0, error: 'baz bat'},
    {index: 1, error: 'foo baz'},
  ])
  const transformed = component.validateBeforeSave()
  deepEqual(transformed, [{message: 'foo bar'}, {message: 'baz bat'}, {message: 'foo baz'}])
})

test('it returns null if no errors on validation', () => {
  editor.getErrors.returns([])
  equal(null, component.validateBeforeSave())
})

test('it saves successfully when editor saves successfully', assert => {
  const resolved = assert.async()
  const cyoePromise = makePromise()

  editor.saveRule.returns(cyoePromise)

  const promise = component.save()
  promise.then(() => {
    ok(true)
    resolved()
  })
  cyoePromise.then.args[0][0]()
})

test('it fails when editor fails', assert => {
  const resolved = assert.async()
  const cyoePromise = makePromise()
  editor.saveRule.returns(cyoePromise)

  const promise = component.save()
  promise.fail(reason => {
    equal(reason, 'stuff happened')
    resolved()
  })
  cyoePromise.catch.args[0][0]('stuff happened')
})

test('it times out', assert => {
  const resolved = assert.async()
  const cyoePromise = makePromise()
  editor.saveRule.returns(cyoePromise)

  const promise = component.save(2)
  promise.fail(reason => {
    ok(reason.match(/timeout/))
    resolved()
  })
})

test('it updates assignments', assert => {
  component.updateAssignment({
    points_possible: 100,
  })
  ok(editor.updateAssignment.calledWithMatch({points_possible: 100}))
})

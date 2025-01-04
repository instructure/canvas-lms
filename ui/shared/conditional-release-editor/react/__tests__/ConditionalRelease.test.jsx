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
import ConditionalRelease from '../index'

const ok = x => expect(x).toBeTruthy()
const equal = (x, y) => expect(x).toEqual(y)
const deepEqual = (x, y) => expect(x).toEqual(y)

let editor = null
class ConditionalReleaseEditor {
  constructor(env) {
    editor = {
      attach: jest.fn(),
      updateAssignment: jest.fn(),
      saveRule: jest.fn(),
      getErrors: jest.fn(),
      focusOnError: jest.fn(),
      env,
    }
    return editor
  }
}
window.conditional_release_module = {ConditionalReleaseEditor}

let component = null
const createComponent = () => {
  component = TestUtils.renderIntoDocument(
    <ConditionalRelease.Editor env={assignmentEnv} type="foo" />,
  )
  component.createNativeEditor()
}

const makePromise = () => {
  const promise = {}
  promise.then = jest.fn().mockReturnValue(promise)
  promise.catch = jest.fn().mockReturnValue(promise)
  return promise
}

let ajax = null
const assignmentEnv = {assignment: {id: 1}, course_id: 1}

describe('Conditional Release component', () => {
  beforeEach(() => {
    ajax = jest.spyOn($, 'ajax')
    createComponent()
  })

  afterEach(() => {
    if (component) {
      const componentNode = ReactDOM.findDOMNode(component)
      if (componentNode) {
        ReactDOM.unmountComponentAtNode(componentNode.parentNode)
      }
    }
    component = null
    editor = null
    jest.restoreAllMocks()
  })

  test('it creates a cyoe editor', () => {
    expect(editor.attach.mock.calls).toHaveLength(1)
  })

  test('it forwards focusOnError', () => {
    component.focusOnError()
    expect(editor.focusOnError.mock.calls).toHaveLength(1)
  })

  test('it transforms validations', () => {
    editor.getErrors.mockReturnValue([
      {index: 0, error: 'foo bar'},
      {index: 0, error: 'baz bat'},
      {index: 1, error: 'foo baz'},
    ])
    const transformed = component.validateBeforeSave()
    deepEqual(transformed, [{message: 'foo bar'}, {message: 'baz bat'}, {message: 'foo baz'}])
  })

  test('it returns null if no errors on validation', () => {
    editor.getErrors.mockReturnValue([])
    equal(null, component.validateBeforeSave())
  })

  test('it saves successfully when editor saves successfully', resolved => {
    const cyoePromise = makePromise()

    editor.saveRule.mockReturnValue(cyoePromise)

    const promise = component.save()
    promise.then(() => {
      ok(true)
      resolved()
    })
    cyoePromise.then.mock.calls[0][0]()
  })

  test('it fails when editor fails', resolved => {
    const cyoePromise = makePromise()
    editor.saveRule.mockReturnValue(cyoePromise)

    const promise = component.save()
    promise.fail(reason => {
      equal(reason, 'stuff happened')
      resolved()
    })
    cyoePromise.catch.mock.calls[0][0]('stuff happened')
  })

  test('it times out', resolved => {
    const cyoePromise = makePromise()
    editor.saveRule.mockReturnValue(cyoePromise)

    const promise = component.save(2)
    promise.fail(reason => {
      ok(reason.match(/timeout/))
      resolved()
    })
  })

  test('it updates assignments', () => {
    component.updateAssignment({
      points_possible: 100,
    })
    expect(editor.updateAssignment).toHaveBeenCalledWith({points_possible: 100})
  })
})

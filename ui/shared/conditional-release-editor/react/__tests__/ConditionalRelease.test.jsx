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
import {render, act} from '@testing-library/react'
import ConditionalRelease from '../index'

describe('ConditionalRelease Editor', () => {
  let editor
  const assignmentEnv = {assignment: {id: 1}, course_id: 1}

  const makePromise = () => {
    const promise = {}
    promise.then = jest.fn().mockReturnValue(promise)
    promise.catch = jest.fn().mockReturnValue(promise)
    return promise
  }

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

  const renderComponent = async () => {
    // Mock DOM elements that the editor needs
    document.body.innerHTML = `
      <div id="canvas-conditional-release-editor"></div>
      <div id="application"></div>
    `

    // Setup the editor module
    window.conditional_release_module = {ConditionalReleaseEditor}

    // Create a ref to access component instance
    const ref = React.createRef()

    // Render the component
    const component = render(<ConditionalRelease.Editor ref={ref} env={assignmentEnv} type="foo" />)

    // Wait for editor to be created
    await act(async () => {
      await new Promise(resolve => setTimeout(resolve, 0))
    })

    return {
      ...component,
      editor,
      ref,
    }
  }

  beforeEach(() => {
    editor = null
  })

  afterEach(() => {
    delete window.conditional_release_module
    document.body.innerHTML = ''
  })

  it('creates and attaches the editor', async () => {
    const {editor} = await renderComponent()
    expect(editor.attach).toHaveBeenCalledWith(
      document.getElementById('canvas-conditional-release-editor'),
      document.getElementById('application'),
    )
  })

  it('validates before save and transforms errors', async () => {
    const {ref} = await renderComponent()

    editor.getErrors.mockReturnValue([
      {index: 0, error: 'foo bar'},
      {index: 0, error: 'baz bat'},
      {index: 1, error: 'foo baz'},
    ])

    const errors = ref.current.validateBeforeSave()
    expect(errors).toEqual([{message: 'foo bar'}, {message: 'baz bat'}, {message: 'foo baz'}])
  })

  it('returns null when validation passes', async () => {
    const {ref} = await renderComponent()

    editor.getErrors.mockReturnValue([])
    expect(ref.current.validateBeforeSave()).toBeNull()
  })

  it('saves successfully', async () => {
    const {ref} = await renderComponent()

    const cyoePromise = makePromise()
    editor.saveRule.mockReturnValue(cyoePromise)

    const savePromise = ref.current.save()
    cyoePromise.then.mock.calls[0][0]()

    await expect(savePromise).resolves.toBeUndefined()
  })

  it('handles save failures', async () => {
    const {ref} = await renderComponent()

    const cyoePromise = makePromise()
    editor.saveRule.mockReturnValue(cyoePromise)

    const savePromise = ref.current.save()
    cyoePromise.catch.mock.calls[0][0]('save failed')

    await expect(savePromise).rejects.toBe('save failed')
  })

  it('times out after specified duration', async () => {
    const {ref} = await renderComponent()

    const cyoePromise = makePromise()
    editor.saveRule.mockReturnValue(cyoePromise)

    const savePromise = ref.current.save(1)
    await expect(savePromise).rejects.toBe('timeout')
  })

  it('updates assignments with new values', async () => {
    const {ref} = await renderComponent()

    const newAssignment = {
      grading_standard_id: 1,
      grading_type: 'points',
      id: 2,
      points_possible: 100,
      submission_types: ['online_text_entry'],
    }

    ref.current.updateAssignment(newAssignment)

    expect(editor.updateAssignment).toHaveBeenCalledWith(newAssignment)
  })

  it('handles not_graded assignments correctly', async () => {
    const {ref} = await renderComponent()

    const newAssignment = {
      grading_type: 'not_graded',
      id: 2,
      points_possible: 100,
    }

    ref.current.updateAssignment(newAssignment)

    expect(editor.updateAssignment).toHaveBeenCalledWith({
      ...newAssignment,
      id: null,
    })
  })
})

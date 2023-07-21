/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import PostTypes from '@canvas/post-assignment-grades-tray/react/PostTypes'

QUnit.module('PostAssignmentGradesTray PostTypes', suiteHooks => {
  let $container
  let context

  function getLabel(text) {
    return [...$container.querySelectorAll('label')].find($label => $label.textContent === text)
  }

  function getGradedPostType() {
    const labelText =
      'GradedStudents who have received a grade or a submission comment will be able to see their grade and/or submission comments.'
    return document.getElementById(getLabel(labelText).htmlFor)
  }

  function getEveryonePostType() {
    const labelText =
      'EveryoneAll students will be able to see their grade and/or submission comments.'
    return document.getElementById(getLabel(labelText).htmlFor)
  }

  function getPostTypeInputs() {
    const inputs = $container.querySelectorAll('input[type=radio]')
    if (inputs.length === 0) return undefined
    return [...inputs]
  }

  function mountComponent() {
    ReactDOM.render(<PostTypes {...context} />, $container)
  }

  suiteHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))
    context = {
      anonymousGrading: false,
      defaultValue: 'everyone',
      disabled: false,
      postTypeChanged: () => {},
    }
  })

  suiteHooks.afterEach(() => {
    ReactDOM.unmountComponentAtNode($container)
    $container.remove()
  })

  test('"Everyone" type includes description"', () => {
    mountComponent()
    const labelText =
      'EveryoneAll students will be able to see their grade and/or submission comments.'
    ok(getLabel(labelText))
  })

  test('"Graded" type includes description"', () => {
    mountComponent()
    const labelText =
      'GradedStudents who have received a grade or a submission comment will be able to see their grade and/or submission comments.'
    ok(getLabel(labelText))
  })

  test('the defaultValue is selected', () => {
    context.defaultValue = 'graded'
    mountComponent()
    strictEqual(getGradedPostType().checked, true)
  })

  test('selecting another type calls postTypeChanged', () => {
    const postTypeChangedSpy = sinon.spy()
    context.postTypeChanged = postTypeChangedSpy
    mountComponent()
    getGradedPostType().click()
    strictEqual(postTypeChangedSpy.callCount, 1)
  })

  QUnit.module('anonymousGrading prop', () => {
    test('anonymousGrading forces EVERYONE type', () => {
      context.anonymousGrading = true
      context.defaultValue = 'graded'
      mountComponent()
      strictEqual(getEveryonePostType().checked, true)
    })

    test('anonymousGrading disables GRADED type', () => {
      context.anonymousGrading = true
      mountComponent()
      strictEqual(getGradedPostType().disabled, true)
    })
  })

  QUnit.module('"disabled" prop', () => {
    test('inputs are enabled when false', () => {
      mountComponent()
      strictEqual(
        getPostTypeInputs().every($input => !$input.disabled),
        true
      )
    })

    test('inputs are disabled when true', () => {
      context.disabled = true
      mountComponent()
      strictEqual(
        getPostTypeInputs().every($input => $input.disabled),
        true
      )
    })
  })
})

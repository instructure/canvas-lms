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
import ReactDOM from 'react-dom'

import GradeOverrideEntry from '@canvas/grading/GradeEntry/GradeOverrideEntry'
import ReadOnlyCell from 'ui/features/gradebook/react/default_gradebook/GradebookGrid/editors/TotalGradeOverrideCellEditor/ReadOnlyCell'

QUnit.module('GradebookGrid TotalGradeOverrideCellEditor ReadOnlyCell', suiteHooks => {
  let $container
  let component
  let props

  suiteHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))

    const gradeEntry = new GradeOverrideEntry()

    props = {
      gradeEntry,
      gradeInfo: gradeEntry.parseValue('91%'),
      gradeIsUpdating: false,
      onGradeUpdate: sinon.stub(),
      pendingGradeInfo: null,
    }
  })

  suiteHooks.afterEach(() => {
    ReactDOM.unmountComponentAtNode($container)
    $container.remove()
  })

  function mountComponent() {
    component = ReactDOM.render(<ReadOnlyCell {...props} />, $container)
  }

  function getGrade() {
    return $container.querySelector('.Grid__GradeCell__Content').textContent
  }

  QUnit.module('#render()', () => {
    test('displays the given grade info in the input', () => {
      mountComponent()
      equal(getGrade(), '91%')
    })

    test('displays the given pending grade info in the input', () => {
      props.pendingGradeInfo = props.gradeEntry.parseValue('92%')
      mountComponent()
      equal(getGrade(), '92%')
    })
  })

  QUnit.module('#applyValue()', () => {
    test('has no effect', () => {
      mountComponent()
      try {
        component.applyValue()
        ok('method does not cause an exception')
      } catch (e) {
        notOk(e, 'method must not cause an exception')
      }
    })
  })

  QUnit.module('#focus()', () => {
    test('does not change focus', () => {
      const previousActiveElement = document.activeElement
      mountComponent()
      component.focus()
      strictEqual(document.activeElement, previousActiveElement)
    })
  })

  QUnit.module('#handleKeyDown()', () => {
    test('does not skip SlickGrid default behavior', () => {
      mountComponent()
      const event = new Event('keydown')
      event.which = 9 // tab
      const continueHandling = component.handleKeyDown(event)
      equal(typeof continueHandling, 'undefined')
    })
  })

  QUnit.module('#isValueChanged()', () => {
    test('returns false', () => {
      mountComponent()
      strictEqual(component.isValueChanged(), false)
    })
  })
})

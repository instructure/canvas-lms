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

import AdvancedTabPanel from 'ui/features/gradebook/react/default_gradebook/components/AdvancedTabPanel'

QUnit.module('GradebookSettingsModal AdvancedTabPanel', suiteHooks => {
  let $container
  let props

  suiteHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))

    props = {
      courseSettings: {
        allowFinalGradeOverride: false,
      },

      onCourseSettingsChange: sinon.spy(),
    }
  })

  suiteHooks.afterEach(() => {
    ReactDOM.unmountComponentAtNode($container)
  })

  function mountComponent() {
    ReactDOM.render(<AdvancedTabPanel {...props} />, $container)
  }

  function findCheckbox(label) {
    const $label = [...$container.querySelectorAll('label')].find(
      $el => $el.innerText.trim() === label
    )
    return $container.querySelector(`#${$label.getAttribute('for')}`)
  }

  function getAllowFinalGradeOverridesCheckbox() {
    return findCheckbox('Allow final grade override')
  }

  QUnit.module('"Allow final grade override" option', () => {
    QUnit.module('when "allow final grade override" is enabled', contextHooks => {
      contextHooks.beforeEach(() => {
        props.courseSettings.allowFinalGradeOverride = true
        mountComponent()
      })

      test('is checked', () => {
        const {checked} = getAllowFinalGradeOverridesCheckbox()
        strictEqual(checked, true)
      })

      test('calls the .onCourseSettingsChange callback when changed', () => {
        getAllowFinalGradeOverridesCheckbox().click()
        strictEqual(props.onCourseSettingsChange.callCount, 1)
      })

      test('includes the new setting when calling the .onCourseSettingsChange callback', () => {
        getAllowFinalGradeOverridesCheckbox().click()
        const [{allowFinalGradeOverride}] = props.onCourseSettingsChange.lastCall.args
        strictEqual(allowFinalGradeOverride, false)
      })
    })

    QUnit.module('when "allow final grade override" is disabled', contextHooks => {
      contextHooks.beforeEach(() => {
        props.courseSettings.allowFinalGradeOverride = false
        mountComponent()
      })

      test('is checked', () => {
        const {checked} = getAllowFinalGradeOverridesCheckbox()
        strictEqual(checked, false)
      })

      test('calls the .onCourseSettingsChange callback when changed', () => {
        getAllowFinalGradeOverridesCheckbox().click()
        strictEqual(props.onCourseSettingsChange.callCount, 1)
      })

      test('includes the new setting when calling the .onCourseSettingsChange callback', () => {
        getAllowFinalGradeOverridesCheckbox().click()
        const [{allowFinalGradeOverride}] = props.onCourseSettingsChange.lastCall.args
        strictEqual(allowFinalGradeOverride, true)
      })
    })
  })
})

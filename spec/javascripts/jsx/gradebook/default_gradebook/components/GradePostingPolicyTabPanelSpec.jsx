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
import GradePostingPolicyTabPanel from 'ui/features/gradebook/react/default_gradebook/components/GradePostingPolicyTabPanel'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'

QUnit.module('GradePostingPolicyTabPanel', moduleHooks => {
  let postPoliciesOnChangeStub
  let showFlashAlertStub
  let $container

  function renderComponent({settings, props} = {}) {
    $container = document.body.appendChild(document.createElement('div'))
    const componentProps = {
      anonymousAssignmentsPresent: true,
      gradebookIsEditable: true,
      onChange: postPoliciesOnChangeStub,
      settings: {
        postManually: false,
        ...settings,
      },
      ...props,
    }
    ReactDOM.render(<GradePostingPolicyTabPanel {...componentProps} />, $container)
    return $container.children[0]
  }

  function automaticPostingButton() {
    return document.getElementById('GradePostingPolicyTabPanel__PostAutomatically')
  }

  function manualPostingButton() {
    return document.getElementById('GradePostingPolicyTabPanel__PostManually')
  }

  moduleHooks.beforeEach(() => {
    postPoliciesOnChangeStub = sinon.stub()
    showFlashAlertStub = sinon.spy(FlashAlert, 'showFlashAlert')
  })

  moduleHooks.afterEach(() => {
    FlashAlert.destroyContainer()
    showFlashAlertStub.restore()
    ReactDOM.unmountComponentAtNode($container)
    $container.remove()
  })

  test('it renders', () => {
    renderComponent()
    const panelContainer = $container.querySelectorAll('#GradePostingPolicyTabPanel__Container')
    equal(panelContainer.length, 1)
  })

  QUnit.module('Course Post Policies', () => {
    QUnit.module('when postManually is false', () => {
      test('automatic posting is selected', () => {
        renderComponent({settings: {postManually: false}})
        const {checked} = automaticPostingButton()
        strictEqual(checked, true)
      })
    })

    QUnit.module('when postManually is true', () => {
      test('manual posting is selected', () => {
        renderComponent({settings: {postManually: true}})
        const {checked} = manualPostingButton()
        strictEqual(checked, true)
      })
    })

    test('are disabled if gradebook cannot be edited by user', () => {
      renderComponent({props: {gradebookIsEditable: false}})
      strictEqual(automaticPostingButton().disabled, true)
      strictEqual(manualPostingButton().disabled, true)
    })

    test('are enabled if gradebook can be edited by user', () => {
      renderComponent({props: {gradebookIsEditable: true}})
      strictEqual(automaticPostingButton().disabled, false)
      strictEqual(manualPostingButton().disabled, false)
    })

    test('onChange is called when automatic posting is selected', () => {
      renderComponent({settings: {postManually: true}})
      automaticPostingButton().click()
      strictEqual(postPoliciesOnChangeStub.callCount, 1)
    })

    test('onChange is called when manual posting is selected', () => {
      renderComponent({settings: {postManually: false}})
      manualPostingButton().click()
      strictEqual(postPoliciesOnChangeStub.callCount, 1)
    })

    test('selecting automatic posting shows a flash alert when anonymousAssignmentsPresent is true', () => {
      renderComponent({settings: {postManually: true}, props: {anonymousAssignmentsPresent: true}})
      automaticPostingButton().click()
      strictEqual(showFlashAlertStub.callCount, 1)
    })

    test('selecting automatic posting does not show a flash alert when anonymousAssignmentsPresent is false', () => {
      renderComponent({settings: {postManually: true}, props: {anonymousAssignmentsPresent: false}})
      automaticPostingButton().click()
      strictEqual(showFlashAlertStub.callCount, 0)
    })
  })
})

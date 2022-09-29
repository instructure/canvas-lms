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

import Layout from 'ui/features/gradebook/react/AssignmentPostingPolicyTray/Layout'

QUnit.module('AssignmentPostingPolicyTray Layout', suiteHooks => {
  let $container
  let context

  function getCancelButton() {
    return [...$container.querySelectorAll('button')].find(
      $button => $button.textContent === 'Cancel'
    )
  }

  function getSaveButton() {
    return [...$container.querySelectorAll('button')].find(
      $button => $button.textContent === 'Save'
    )
  }

  function getLabel(text) {
    return [...$container.querySelectorAll('label')].find($label =>
      $label.textContent.includes(text)
    )
  }

  function getInputByLabel(label) {
    const $label = getLabel(label)
    if ($label === undefined) return undefined
    return document.getElementById($label.htmlFor)
  }

  function getAutomaticallyPostInput() {
    return getInputByLabel('Automatically')
  }

  function getManuallyPostInput() {
    return getInputByLabel('Manually')
  }

  function getLabelWithManualPostingDetail() {
    return getLabel('While the grades for this assignment are set to manual')
  }

  function mountComponent() {
    ReactDOM.render(<Layout {...context} />, $container)
  }

  suiteHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))
    context = {
      allowAutomaticPosting: true,
      allowCanceling: true,
      allowSaving: true,
      onPostPolicyChanged: () => {},
      onDismiss: () => {},
      onSave: () => {},
      originalPostManually: true,
      selectedPostManually: false,
    }
  })

  suiteHooks.afterEach(() => {
    ReactDOM.unmountComponentAtNode($container)
    $container.remove()
  })

  test('clicking "Cancel" button calls the onDismiss prop', () => {
    sinon.spy(context, 'onDismiss')
    mountComponent()
    getCancelButton().click()
    const {
      onDismiss: {callCount},
    } = context
    strictEqual(callCount, 1)
  })

  test('the "Cancel" button is enabled when allowCanceling is true', () => {
    mountComponent()

    strictEqual(getCancelButton().disabled, false)
  })

  test('the "Cancel" button is disabled when allowCanceling is false', () => {
    context.allowCanceling = false
    mountComponent()

    strictEqual(getCancelButton().disabled, true)
  })

  test('clicking "Save" button calls the onSave prop', () => {
    sinon.spy(context, 'onSave')
    mountComponent()
    getSaveButton().click()
    const {
      onSave: {callCount},
    } = context
    strictEqual(callCount, 1)
  })

  test('the "Save" button is enabled when allowSaving is true', () => {
    mountComponent()

    strictEqual(getSaveButton().disabled, false)
  })

  test('the "Save" button is disabled when allowSaving is false', () => {
    context.allowSaving = false
    mountComponent()

    strictEqual(getSaveButton().disabled, true)
  })

  QUnit.module('when allowAutomaticPosting is true', allowAutoPostingHooks => {
    allowAutoPostingHooks.beforeEach(() => {
      context.allowAutomaticPosting = true
    })

    test('the "Automatically" radio input is enabled', () => {
      mountComponent()
      strictEqual(getAutomaticallyPostInput().disabled, false)
    })

    test('the "Manually" radio input is enabled', () => {
      mountComponent()
      strictEqual(getManuallyPostInput().disabled, false)
    })
  })

  QUnit.module('when allowAutomaticPosting is false', preventAutoPostingHooks => {
    preventAutoPostingHooks.beforeEach(() => {
      context.allowAutomaticPosting = false
    })

    test('the "Automatically" radio input is disabled', () => {
      mountComponent()
      strictEqual(getAutomaticallyPostInput().disabled, true)
    })

    test('the "Manually" radio input is enabled', () => {
      mountComponent()
      strictEqual(getManuallyPostInput().disabled, false)
    })
  })

  QUnit.module('when selectedPostManually is true', postManuallyTrueHooks => {
    postManuallyTrueHooks.beforeEach(() => {
      context.selectedPostManually = true
    })

    test('the "Manually" radio input is selected', () => {
      mountComponent()
      strictEqual(getManuallyPostInput().checked, true)
    })

    test('additional explicatory text on the nature of manual posting is displayed', () => {
      mountComponent()
      ok(getLabelWithManualPostingDetail())
    })
  })

  QUnit.module('when selectedPostManually is false', postManuallyFalseHooks => {
    postManuallyFalseHooks.afterEach(() => {
      context.selectedPostManually = false
    })

    test('the "Automatically" radio input is selected', () => {
      mountComponent()
      strictEqual(getAutomaticallyPostInput().checked, true)
    })

    test('no additional text on the nature of manual posting is displayed', () => {
      mountComponent()
      strictEqual(getLabelWithManualPostingDetail(), undefined)
    })
  })

  test('clicking the "Manually" input calls onPostPolicyChanged', () => {
    sinon.spy(context, 'onPostPolicyChanged')
    mountComponent()
    getManuallyPostInput().click()
    strictEqual(context.onPostPolicyChanged.callCount, 1)
  })

  test('clicking the "Manually" input passes postManually: true to onPostPolicyChanged', () => {
    sinon.spy(context, 'onPostPolicyChanged')
    mountComponent()
    getManuallyPostInput().click()
    const [params] = context.onPostPolicyChanged.firstCall.args
    strictEqual(params.postManually, true)
  })

  test('clicking the "Automatically" input calls onPostPolicyChanged', () => {
    context.selectedPostManually = true
    sinon.spy(context, 'onPostPolicyChanged')
    mountComponent()

    getAutomaticallyPostInput().click()
    strictEqual(context.onPostPolicyChanged.callCount, 1)
  })

  test('clicking the "Automatically" input passes postManually: false to onPostPolicyChanged', () => {
    context.selectedPostManually = true
    sinon.spy(context, 'onPostPolicyChanged')
    mountComponent()
    getAutomaticallyPostInput().click()

    const [params] = context.onPostPolicyChanged.firstCall.args
    strictEqual(params.postManually, false)
  })
})

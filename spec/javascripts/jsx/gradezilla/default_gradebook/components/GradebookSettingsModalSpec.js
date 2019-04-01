/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import {fireEvent, wait} from 'react-testing-library'

import GradebookSettingsModal from 'jsx/gradezilla/default_gradebook/components/GradebookSettingsModal'
import * as GradebookSettingsModalApi from 'jsx/gradezilla/default_gradebook/apis/GradebookSettingsModalApi'
import * as FlashAlert from 'jsx/shared/FlashAlert'
import CourseSettings from 'jsx/gradezilla/default_gradebook/CourseSettings'
import PostPolicies from 'jsx/gradezilla/default_gradebook/PostPolicies'
import * as PostPolicyApi from 'jsx/gradezilla/default_gradebook/PostPolicies/PostPolicyApi'
import {createGradebook} from 'jsx/gradezilla/default_gradebook/__tests__/GradebookSpecHelper'

/* eslint-disable qunit/no-identical-names */
QUnit.module('GradebookSettingsModal', suiteHooks => {
  let $container
  let component
  let gradebook
  let props

  let updatedCourseSettings
  let fetchedLatePolicy
  let existingLatePolicy
  let newLatePolicy
  let postPolicy

  let fetchLatePolicyPromise
  let createLatePolicyPromise
  let updateLatePolicyPromise
  let setCoursePostPolicyPromise
  let updateCourseSettingsPromise

  suiteHooks.beforeEach(() => {
    $container = document.createElement('div')
    document.body.appendChild($container)

    gradebook = createGradebook({post_manually: false})

    updatedCourseSettings = {allowFinalGradeOverride: true}
    fetchedLatePolicy = GradebookSettingsModalApi.DEFAULT_LATE_POLICY_DATA
    newLatePolicy = GradebookSettingsModalApi.DEFAULT_LATE_POLICY_DATA
    existingLatePolicy = {
      id: '2901',
      lateSubmissionDeduction: 0,
      lateSubmissionDeductionEnabled: false,
      lateSubmissionInterval: 'day',
      lateSubmissionMinimumPercent: 0,
      lateSubmissionMinimumPercentEnabled: false,
      missingSubmissionDeduction: 0,
      missingSubmissionDeductionEnabled: false
    }
    postPolicy = {postManually: true}

    props = {
      anonymousAssignmentsPresent: false,
      courseFeatures: {
        finalGradeOverrideEnabled: true
      },
      courseId: '1201',
      courseSettings: new CourseSettings(gradebook, {allowFinalGradeOverride: false}),
      gradedLateSubmissionsExist: true,
      locale: 'en',
      onClose: sinon.spy(),
      onCourseSettingsUpdated: sinon.spy(),
      onEntered: sinon.spy(),
      onLatePolicyUpdate() {},
      postPolicies: new PostPolicies(gradebook)
    }

    fetchLatePolicyPromise = {}
    fetchLatePolicyPromise.promise = new Promise((resolve, reject) => {
      fetchLatePolicyPromise.resolve = () => {
        resolve({data: {latePolicy: fetchedLatePolicy}})
      }
      fetchLatePolicyPromise.reject = reject
    })
    sandbox
      .stub(GradebookSettingsModalApi, 'fetchLatePolicy')
      .returns(fetchLatePolicyPromise.promise)

    createLatePolicyPromise = {}
    createLatePolicyPromise.promise = new Promise((resolve, reject) => {
      createLatePolicyPromise.resolve = () => {
        resolve({data: {latePolicy: existingLatePolicy}})
      }
      createLatePolicyPromise.reject = reject
    })
    sandbox
      .stub(GradebookSettingsModalApi, 'createLatePolicy')
      .returns(createLatePolicyPromise.promise)

    updateLatePolicyPromise = {}
    updateLatePolicyPromise.promise = new Promise((resolve, reject) => {
      updateLatePolicyPromise.resolve = () => {
        resolve({data: {latePolicy: existingLatePolicy}})
      }
      updateLatePolicyPromise.reject = reject
    })
    sandbox
      .stub(GradebookSettingsModalApi, 'updateLatePolicy')
      .returns(updateLatePolicyPromise.promise)

    setCoursePostPolicyPromise = {}
    setCoursePostPolicyPromise.promise = new Promise((resolve, reject) => {
      setCoursePostPolicyPromise.resolve = () => {
        resolve(postPolicy)
      }
      setCoursePostPolicyPromise.reject = reject
    })
    sandbox.stub(PostPolicyApi, 'setCoursePostPolicy').returns(setCoursePostPolicyPromise.promise)

    updateCourseSettingsPromise = {}
    updateCourseSettingsPromise.promise = new Promise((resolve, reject) => {
      updateCourseSettingsPromise.resolve = () => {
        resolve({data: updatedCourseSettings})
      }
      updateCourseSettingsPromise.reject = reject
    })
    sandbox
      .stub(GradebookSettingsModalApi, 'updateCourseSettings')
      .returns(updateCourseSettingsPromise.promise)
  })

  suiteHooks.afterEach(async () => {
    await ensureModalIsClosed()
    ReactDOM.unmountComponentAtNode($container)
    $container.remove()
  })

  function mountComponent() {
    const bindRef = ref => {
      component = ref
    }
    ReactDOM.render(<GradebookSettingsModal ref={bindRef} {...props} />, $container)
  }

  function getModalElement() {
    return document.querySelector('[role="dialog"][aria-label="Gradebook Settings"]')
  }

  async function openModal() {
    component.open()
    await wait(() => {
      if (props.onEntered.callCount > 0) {
        return
      }
      throw new Error('Modal is not yet open')
    })
  }

  async function mountAndOpen() {
    mountComponent()
    await openModal()
  }

  async function mountOpenAndLoad() {
    await mountAndOpen()
    fetchLatePolicyPromise.resolve()
    await wait(() => !getSpinner())
  }

  async function mountOpenLoadAndSelectTab(tabLabel) {
    await mountOpenAndLoad()
    findTab(tabLabel).click()
  }

  async function waitForModalClosed() {
    await wait(() => {
      if (props.onClose.callCount > 0) {
        return
      }
      throw new Error('Modal is still open')
    })
  }

  async function ensureModalIsClosed() {
    if (getModalElement()) {
      component.close()
      await waitForModalClosed()
    }
  }

  function getSpinner() {
    return [...getModalElement().querySelectorAll('svg title')].find($title =>
      $title.textContent.includes('Loading')
    )
  }

  function findTab(label) {
    return [...getModalElement().querySelectorAll('[role="tab"]')].find($tab =>
      $tab.textContent.includes(label)
    )
  }

  function getGradePostingPolicyTab() {
    return findTab('Grade Posting Policy')
  }

  function getAdvancedTab() {
    return findTab('Advanced')
  }

  function findCheckbox(label) {
    const $modal = getModalElement()
    const $label = [...$modal.querySelectorAll('label')].find($el =>
      $el.textContent.includes(label)
    )
    return $modal.querySelector(`#${$label.getAttribute('for')}`)
  }

  function getAutomaticallyApplyMissingCheckbox() {
    return findCheckbox('Automatically apply grade for missing submissions')
  }

  function getManuallyPostGradesOption() {
    return findCheckbox('Manually Post Grades')
  }

  function getAutomaticallyPostGradesOption() {
    return findCheckbox('Automatically Post Grades')
  }

  function getAllowFinalGradeOverrideCheckbox() {
    return findCheckbox('Allow final grade override')
  }

  function getUpdateButton() {
    return getModalElement().querySelector('#gradebook-settings-update-button')
  }

  QUnit.module('#open()', () => {
    test('opens the modal', async () => {
      mountComponent()
      await openModal()
      ok(getModalElement())
    })
  })

  QUnit.module('#close()', () => {
    test('closes the modal', async () => {
      mountComponent()
      await openModal()
      component.close()
      await waitForModalClosed()
      notOk(getModalElement())
    })
  })

  QUnit.module('upon opening', () => {
    test('sends a request for the course late policy', async () => {
      await mountOpenAndLoad()
      strictEqual(GradebookSettingsModalApi.fetchLatePolicy.callCount, 1)
    })

    test('includes the course id when requesting the course late policy', async () => {
      await mountOpenAndLoad()
      const [courseId] = GradebookSettingsModalApi.fetchLatePolicy.lastCall.args
      strictEqual(courseId, '1201')
    })
  })

  QUnit.module('"Grade Posting Policy" tab', () => {
    test('is present when "Post Policies" is enabled', async () => {
      await mountOpenAndLoad()
      ok(getGradePostingPolicyTab())
    })

    test('is not present when "Post Policies" is disabled', async () => {
      props.postPolicies = null
      await mountOpenAndLoad()
      notOk(getGradePostingPolicyTab())
    })
  })

  QUnit.module('"Advanced" tab', () => {
    test('is present when "Final Grade Override" is enabled', async () => {
      await mountOpenAndLoad()
      ok(getAdvancedTab())
    })

    test('is not present when "Final Grade Override" is disabled', async () => {
      props.courseFeatures.finalGradeOverrideEnabled = false
      await mountOpenAndLoad()
      notOk(getAdvancedTab())
    })
  })

  QUnit.module('"Update" button', () => {
    test('is disabled when no settings have been changed', async () => {
      await mountOpenAndLoad()
      strictEqual(getUpdateButton().disabled, true)
    })

    test('is enabled when the late policy has been changed', async () => {
      await mountOpenAndLoad()
      getAutomaticallyApplyMissingCheckbox().click()
      strictEqual(getUpdateButton().disabled, false)
    })

    test('is disabled when a late policy change was reverted', async () => {
      await mountOpenAndLoad()
      const $checkbox = getAutomaticallyApplyMissingCheckbox()
      $checkbox.click() // change the setting
      $checkbox.click() // change it back
      strictEqual(getUpdateButton().disabled, true)
    })

    test('is enabled when the grade posting policy has been changed', async () => {
      props.postPolicies.setCoursePostPolicy({postManually: true})
      await mountOpenLoadAndSelectTab('Grade Posting Policy')
      getAutomaticallyPostGradesOption().click()
      strictEqual(getUpdateButton().disabled, false)
    })

    test('is disabled when a grade posting policy change was reverted', async () => {
      props.postPolicies.setCoursePostPolicy({postManually: true})
      await mountOpenLoadAndSelectTab('Grade Posting Policy')
      getAutomaticallyPostGradesOption().click()
      getManuallyPostGradesOption().click()
      strictEqual(getUpdateButton().disabled, true)
    })

    test('is enabled when an advanced settings has been changed', async () => {
      await mountOpenLoadAndSelectTab('Advanced')
      getAllowFinalGradeOverrideCheckbox().click()
      strictEqual(getUpdateButton().disabled, false)
    })

    test('is disabled when an advanced settings change was reverted', async () => {
      await mountOpenLoadAndSelectTab('Advanced')
      getAllowFinalGradeOverrideCheckbox().click()
      getAllowFinalGradeOverrideCheckbox().click()
      strictEqual(getUpdateButton().disabled, true)
    })

    test('is disabled when a late policy change is invalid', async () => {
      await mountOpenAndLoad()
      getAutomaticallyApplyMissingCheckbox().click()
      const $input = getModalElement().querySelector('#missing-submission-grade')
      fireEvent.change($input, {target: {value: '-1'}})
      strictEqual(getUpdateButton().disabled, true)
    })

    QUnit.module('when clicked', () => {
      test('creates a new late policy when none existed', async () => {
        fetchedLatePolicy = newLatePolicy
        await mountOpenAndLoad()
        getAutomaticallyApplyMissingCheckbox().click()
        getUpdateButton().click()
        strictEqual(GradebookSettingsModalApi.createLatePolicy.callCount, 1)
      })

      test('updates the late policy when one exists', async () => {
        fetchedLatePolicy = existingLatePolicy
        await mountOpenAndLoad()
        getAutomaticallyApplyMissingCheckbox().click()
        getUpdateButton().click()
        strictEqual(GradebookSettingsModalApi.updateLatePolicy.callCount, 1)
      })

      test('does not create a late policy when no settings have been changed', async () => {
        await mountOpenAndLoad()
        const $checkbox = getAutomaticallyApplyMissingCheckbox()
        $checkbox.click() // change the setting
        $checkbox.click() // change it back
        getUpdateButton().click()
        strictEqual(GradebookSettingsModalApi.createLatePolicy.callCount, 0)
      })

      test('updates the course post policy when changed', async () => {
        await mountOpenLoadAndSelectTab('Grade Posting Policy')
        getManuallyPostGradesOption().click()
        getUpdateButton().click()
        strictEqual(PostPolicyApi.setCoursePostPolicy.callCount, 1)
      })

      test('does not update the course post policy when unchanged', async () => {
        await mountOpenLoadAndSelectTab('Grade Posting Policy')
        getManuallyPostGradesOption().click()
        getAutomaticallyPostGradesOption().click()
        getUpdateButton().click()
        strictEqual(PostPolicyApi.setCoursePostPolicy.callCount, 0)
      })

      test('updates advanced settings when changed', async () => {
        await mountOpenLoadAndSelectTab('Advanced')
        getAllowFinalGradeOverrideCheckbox().click()
        getUpdateButton().click()
        strictEqual(GradebookSettingsModalApi.updateCourseSettings.callCount, 1)
      })

      test('does not update advanced settings when unchanged', async () => {
        await mountOpenLoadAndSelectTab('Advanced')
        getAllowFinalGradeOverrideCheckbox().click()
        getAllowFinalGradeOverrideCheckbox().click()
        getUpdateButton().click()
        strictEqual(GradebookSettingsModalApi.updateCourseSettings.callCount, 0)
      })

      QUnit.module('when a late policy change is invalid', contextHooks => {
        contextHooks.beforeEach(async () => {
          await mountOpenAndLoad()
          getAutomaticallyApplyMissingCheckbox().click()
          const $input = getModalElement().querySelector('#missing-submission-grade')
          fireEvent.change($input, {target: {value: '-1'}})
        })

        test('does not attempt to create the late policy', () => {
          getUpdateButton().click()
          strictEqual(GradebookSettingsModalApi.createLatePolicy.callCount, 0)
        })

        test('updates the course post policy when changed', () => {
          getGradePostingPolicyTab().click()
          getManuallyPostGradesOption().click()
          getUpdateButton().click()
          strictEqual(PostPolicyApi.setCoursePostPolicy.callCount, 1)
        })

        test('updates advanced settings when changed', () => {
          getAdvancedTab().click()
          getAllowFinalGradeOverrideCheckbox().click()
          getUpdateButton().click()
          strictEqual(GradebookSettingsModalApi.updateCourseSettings.callCount, 1)
        })
      })
    })
  })

  QUnit.module('when creating a new late policy', hooks => {
    hooks.beforeEach(async () => {
      sandbox.spy(FlashAlert, 'showFlashAlert')

      await mountOpenAndLoad()
      getAutomaticallyApplyMissingCheckbox().click()
      getUpdateButton().click()
    })

    hooks.afterEach(() => {
      FlashAlert.destroyContainer()
    })

    test('disables the "Update" button while the request is pending', () => {
      strictEqual(getUpdateButton().disabled, true)
      createLatePolicyPromise.resolve()
    })

    QUnit.module('when the request succeeds', contextHooks => {
      contextHooks.beforeEach(async () => {
        createLatePolicyPromise.resolve()
        await waitForModalClosed()
      })

      test('displays a flash alert', () => {
        strictEqual(FlashAlert.showFlashAlert.callCount, 1)
      })

      test('uses the "success" type for the flash alert', () => {
        const [{type}] = FlashAlert.showFlashAlert.lastCall.args
        equal(type, 'success')
      })

      test('closes the modal', () => {
        notOk(getModalElement())
      })
    })

    QUnit.module('when the request fails', contextHooks => {
      contextHooks.beforeEach(async () => {
        createLatePolicyPromise.reject(new Error('request failed'))
        await wait(() => FlashAlert.showFlashAlert.callCount > 0)
      })

      test('displays a flash alert', () => {
        strictEqual(FlashAlert.showFlashAlert.callCount, 1)
      })

      test('uses the "error" type for the flash alert', () => {
        const [{type}] = FlashAlert.showFlashAlert.lastCall.args
        equal(type, 'error')
      })

      test('does not close the modal', () => {
        ok(getModalElement())
      })
    })
  })

  QUnit.module('when updating the late policy', hooks => {
    hooks.beforeEach(async () => {
      sandbox.spy(FlashAlert, 'showFlashAlert')

      fetchedLatePolicy = existingLatePolicy
      await mountOpenAndLoad()
      getAutomaticallyApplyMissingCheckbox().click()
      getUpdateButton().click()
    })

    hooks.afterEach(() => {
      FlashAlert.destroyContainer()
    })

    test('disables the "Update" button while the request is pending', () => {
      strictEqual(getUpdateButton().disabled, true)
      updateLatePolicyPromise.resolve()
    })

    QUnit.module('when the request succeeds', contextHooks => {
      contextHooks.beforeEach(async () => {
        updateLatePolicyPromise.resolve()
        await waitForModalClosed()
      })

      test('displays a flash alert', () => {
        strictEqual(FlashAlert.showFlashAlert.callCount, 1)
      })

      test('uses the "success" type for the flash alert', () => {
        const [{type}] = FlashAlert.showFlashAlert.lastCall.args
        equal(type, 'success')
      })

      test('closes the modal', () => {
        notOk(getModalElement())
      })
    })

    QUnit.module('when the request fails', contextHooks => {
      contextHooks.beforeEach(async () => {
        updateLatePolicyPromise.reject(new Error('request failed'))
        await wait(() => FlashAlert.showFlashAlert.callCount > 0)
      })

      test('displays a flash alert', () => {
        strictEqual(FlashAlert.showFlashAlert.callCount, 1)
      })

      test('uses the "error" type for the flash alert', () => {
        const [{type}] = FlashAlert.showFlashAlert.lastCall.args
        equal(type, 'error')
      })

      test('does not close the modal', () => {
        ok(getModalElement())
      })
    })
  })

  QUnit.module('when updating the course post policy', hooks => {
    hooks.beforeEach(async () => {
      sandbox.spy(FlashAlert, 'showFlashAlert')

      await mountOpenLoadAndSelectTab('Grade Posting Policy')
      getManuallyPostGradesOption().click()
      getUpdateButton().click()
    })

    hooks.afterEach(() => {
      FlashAlert.destroyContainer()
    })

    test('disables the "Update" button while the request is pending', () => {
      strictEqual(getUpdateButton().disabled, true)
      setCoursePostPolicyPromise.resolve()
    })

    QUnit.module('when the request succeeds', contextHooks => {
      contextHooks.beforeEach(async () => {
        setCoursePostPolicyPromise.resolve()
        await waitForModalClosed()
      })

      test('displays a flash alert', () => {
        strictEqual(FlashAlert.showFlashAlert.callCount, 1)
      })

      test('uses the "success" type for the flash alert', () => {
        const [{type}] = FlashAlert.showFlashAlert.lastCall.args
        equal(type, 'success')
      })

      test('updates the Gradebook Post Policies', () => {
        deepEqual(props.postPolicies.coursePostPolicy, postPolicy)
      })

      test('closes the modal', () => {
        notOk(getModalElement())
      })
    })

    QUnit.module('when the request fails', contextHooks => {
      contextHooks.beforeEach(async () => {
        setCoursePostPolicyPromise.reject(new Error('request failed'))
        await wait(() => FlashAlert.showFlashAlert.callCount > 0)
      })

      test('displays a flash alert', () => {
        strictEqual(FlashAlert.showFlashAlert.callCount, 1)
      })

      test('uses the "error" type for the flash alert', () => {
        const [{type}] = FlashAlert.showFlashAlert.lastCall.args
        equal(type, 'error')
      })

      test('does not update the Gradebook Post Policies', () => {
        notDeepEqual(props.postPolicies.coursePostPolicy, postPolicy)
      })

      test('does not close the modal', () => {
        ok(getModalElement())
      })
    })
  })

  QUnit.module('when updating advanced settings', hooks => {
    hooks.beforeEach(async () => {
      sandbox.spy(FlashAlert, 'showFlashAlert')

      await mountOpenLoadAndSelectTab('Advanced')
      getAllowFinalGradeOverrideCheckbox().click()
      getUpdateButton().click()
    })

    hooks.afterEach(() => {
      FlashAlert.destroyContainer()
    })

    test('disables the "Update" button while the request is pending', () => {
      strictEqual(getUpdateButton().disabled, true)
      updateCourseSettingsPromise.resolve()
    })

    QUnit.module('when the request succeeds', contextHooks => {
      contextHooks.beforeEach(async () => {
        updateCourseSettingsPromise.resolve()
        await waitForModalClosed()
      })

      test('displays a flash alert', () => {
        strictEqual(FlashAlert.showFlashAlert.callCount, 1)
      })

      test('uses the "success" type for the flash alert', () => {
        const [{type}] = FlashAlert.showFlashAlert.lastCall.args
        equal(type, 'success')
      })

      test('calls the onCourseSettingsUpdated callback prop', () => {
        strictEqual(props.onCourseSettingsUpdated.callCount, 1)
      })

      test('includes the updated settings when calling onCourseSettingsUpdated', () => {
        const [settings] = props.onCourseSettingsUpdated.lastCall.args
        deepEqual(settings, updatedCourseSettings)
      })

      test('closes the modal', () => {
        notOk(getModalElement())
      })
    })

    QUnit.module('when the request fails', contextHooks => {
      contextHooks.beforeEach(async () => {
        updateCourseSettingsPromise.reject(new Error('request failed'))
        await wait(() => FlashAlert.showFlashAlert.callCount > 0)
      })

      test('displays a flash alert', () => {
        strictEqual(FlashAlert.showFlashAlert.callCount, 1)
      })

      test('uses the "error" type for the flash alert', () => {
        const [{type}] = FlashAlert.showFlashAlert.lastCall.args
        equal(type, 'error')
      })

      test('does not call the onCourseSettingsUpdated callback prop', () => {
        strictEqual(props.onCourseSettingsUpdated.callCount, 0)
      })

      test('does not close the modal', () => {
        ok(getModalElement())
      })
    })
  })

  QUnit.module('"Cancel" button', () => {
    function getCancelButton() {
      return getModalElement().querySelector('#gradebook-settings-cancel-button')
    }

    QUnit.module('when clicked', () => {
      test('closes the modal', async () => {
        await mountAndOpen()
        getCancelButton().click()
        await waitForModalClosed()
        notOk(getModalElement())
      })
    })
  })
})
/* eslint-enable qunit/no-identical-names */

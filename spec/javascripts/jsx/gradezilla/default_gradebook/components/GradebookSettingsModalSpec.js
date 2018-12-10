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
import {mount} from 'enzyme'

import GradebookSettingsModal from 'jsx/gradezilla/default_gradebook/components/GradebookSettingsModal'
import * as GradebookSettingsModalApi from 'jsx/gradezilla/default_gradebook/apis/GradebookSettingsModalApi'
import * as FlashAlert from 'jsx/shared/FlashAlert'

import {waitFor} from '../../../support/Waiters'

const {
  config: {testTimeout}
} = QUnit

const fixtures = document.getElementById('fixtures')
const defaultProps = {
  courseId: '1',
  locale: 'en',
  onClose() {},
  gradedLateSubmissionsExist: true,
  onLatePolicyUpdate() {},
  overrides: {
    defaultChecked: false,
    disabled: false,
    onChange() {
      return Promise.resolve()
    }
  }
}

const EXISTING_LATE_POLICY = {
  id: '15',
  missingSubmissionDeductionEnabled: false,
  missingSubmissionDeduction: 0,
  lateSubmissionDeductionEnabled: false,
  lateSubmissionDeduction: 0,
  lateSubmissionInterval: 'day',
  lateSubmissionMinimumPercentEnabled: false,
  lateSubmissionMinimumPercent: 0
}

const NEW_LATE_POLICY = {
  ...EXISTING_LATE_POLICY,
  newRecord: true
}

QUnit.module('GradebookSettingsModal', suiteHooks => {
  suiteHooks.beforeEach(() => {
    QUnit.config.testTimeout = 1000
  })

  suiteHooks.afterEach(() => {
    QUnit.config.testTimeout = testTimeout
  })

  QUnit.module('with enzyme', () => {
    function mountComponent(customProps = {}) {
      const props = {...defaultProps, ...customProps}
      return mount(<GradebookSettingsModal {...props} />)
    }

    function stubLatePolicyFetchSuccess(component, customData) {
      const latePolicy = {
        ...EXISTING_LATE_POLICY,
        ...customData
      }
      const fetchSuccess = Promise.resolve({data: {latePolicy}})
      const promise = fetchSuccess.then(component.onFetchLatePolicySuccess)
      sandbox.stub(component, 'fetchLatePolicy').returns(promise)
      return promise
    }

    QUnit.module('modal', moduleHooks => {
      let clock
      let wrapper

      moduleHooks.beforeEach(() => {
        clock = sinon.useFakeTimers()
        const applicationElement = document.createElement('div')
        applicationElement.id = 'application'
        document.getElementById('fixtures').appendChild(applicationElement)
      })

      moduleHooks.afterEach(() => {
        wrapper.unmount()
        FlashAlert.destroyContainer()
        document.getElementById('fixtures').innerHTML = ''
        clock.restore()
      })

      test('is initially closed', () => {
        wrapper = mountComponent()
        equal(wrapper.find('Modal').prop('open'), false)
      })

      test('calling open causes the modal to be rendered', () => {
        wrapper = mountComponent()
        const component = wrapper.instance()
        const fetchLatePolicy = stubLatePolicyFetchSuccess(component)
        component.open()
        return fetchLatePolicy.then(() => {
          wrapper.update()
          equal(wrapper.find('Modal').prop('open'), true)
        })
      })

      test('calling close closes the modal', () => {
        wrapper = mountComponent()
        const component = wrapper.instance()
        const fetchLatePolicy = stubLatePolicyFetchSuccess(component)
        component.open()
        return fetchLatePolicy.then(() => {
          wrapper.update()
          equal(wrapper.find('Modal').prop('open'), true, 'modal is open')
          component.close()
          wrapper.update()
          equal(wrapper.find('Modal').prop('open'), false, 'modal is closed')
        })
      })

      test('clicking cancel closes the modal', () => {
        wrapper = mountComponent()
        const component = wrapper.instance()
        const fetchLatePolicy = stubLatePolicyFetchSuccess(component)
        component.open()
        clock.tick(50) // wait for Modal to transition open
        return fetchLatePolicy.then(() => {
          wrapper.update()
          equal(wrapper.find('Modal').prop('open'), true)
          document.getElementById('gradebook-settings-cancel-button').click()
          wrapper.update()
          equal(wrapper.find('Modal').prop('open'), false)
        })
      })

      test('the "Update" button is disabled when the modal opens', () => {
        wrapper = mountComponent()
        const component = wrapper.instance()
        const fetchLatePolicy = stubLatePolicyFetchSuccess(component)
        component.open()
        clock.tick(50) // wait for Modal to transition open
        return fetchLatePolicy.then(() => {
          wrapper.update()
          const updateButton = document.getElementById('gradebook-settings-update-button')
          ok(updateButton.getAttribute('aria-disabled'))
        })
      })

      test('the "Update" button is enabled if a setting is changed', () => {
        wrapper = mountComponent()
        const component = wrapper.instance()
        const fetchLatePolicy = stubLatePolicyFetchSuccess(component)
        component.open()
        clock.tick(50) // wait for Modal to transition open
        return fetchLatePolicy.then(() => {
          wrapper.update()
          component.changeLatePolicy({
            ...component.state.latePolicy,
            changes: {lateSubmissionDeductionEnabled: true}
          })
          const updateButton = document.getElementById('gradebook-settings-update-button')
          notOk(updateButton.getAttribute('aria-disabled'))
        })
      })

      test('the "Update" button is disabled if a setting is changed, but there are validation errors', () => {
        wrapper = mountComponent()
        const component = wrapper.instance()
        const fetchLatePolicy = stubLatePolicyFetchSuccess(component)
        component.open()
        clock.tick(50) // wait for Modal to transition open
        return fetchLatePolicy.then(() => {
          wrapper.update()
          component.changeLatePolicy({
            ...component.state.latePolicy,
            changes: {lateSubmissionDeductionEnabled: true},
            validationErrors: {
              missingSubmissionDeduction: 'Missing submission percent must be numeric'
            }
          })
          const updateButton = document.getElementById('gradebook-settings-update-button')
          ok(updateButton.getAttribute('aria-disabled'))
        })
      })

      test('clicking "Update" sends a request to update the late policy', () => {
        sandbox.stub(GradebookSettingsModalApi, 'updateLatePolicy').resolves()
        wrapper = mountComponent()
        const component = wrapper.instance()
        const fetchLatePolicy = stubLatePolicyFetchSuccess(component)
        component.open()
        clock.tick(50) // wait for Modal to transition open
        return fetchLatePolicy.then(() => {
          wrapper.update()
          const changes = {lateSubmissionDeductionEnabled: true}
          component.changeLatePolicy({...component.state.latePolicy, changes})
          const button = document.getElementById('gradebook-settings-update-button')
          button.click()
          equal(
            GradebookSettingsModalApi.updateLatePolicy.callCount,
            1,
            'updateLatePolicy is called once'
          )
          const changesArg = GradebookSettingsModalApi.updateLatePolicy.getCall(0).args[1]
          propEqual(changesArg, changes, 'updateLatePolicy is called with the late policy changes')
        })
      })

      test('clicking "Update" sends a post request to create a late policy if one does not yet exist', () => {
        sandbox.stub(GradebookSettingsModalApi, 'createLatePolicy').resolves()
        // When a late policy does not exist, the API call returns 'Not Found'
        wrapper = mountComponent()
        const component = wrapper.instance()
        const fetchLatePolicy = stubLatePolicyFetchSuccess(component, {newRecord: true})
        component.open()
        clock.tick(50) // wait for Modal to transition open

        return fetchLatePolicy.then(() => {
          wrapper.update()
          const changes = {lateSubmissionDeductionEnabled: true}
          component.changeLatePolicy({...component.state.latePolicy, changes})
          document.getElementById('gradebook-settings-update-button').click()
          equal(
            GradebookSettingsModalApi.createLatePolicy.callCount,
            1,
            'createLatePolicy is called once'
          )
          const changesArg = GradebookSettingsModalApi.createLatePolicy.getCall(0).args[1]
          propEqual(changesArg, changes, 'createLatePolicy is called with the late policy changes')
        })
      })
    })
  })

  QUnit.module('without enzyme', () => {
    function renderComponent(props = {}) {
      return ReactDOM.render(<GradebookSettingsModal {...defaultProps} {...props} />, fixtures)
    }

    async function renderAndOpenComponent(props = {}) {
      const component = renderComponent(props)
      component.open()
      const isLatePoliciesFormInDOM = () => document.body.innerText.includes('Late Policies')
      return waitFor(isLatePoliciesFormInDOM)
    }

    function findTab({label}) {
      const tabs = []
      document.querySelectorAll('[role="tab"]').forEach(node => tabs.push(node))
      return tabs.find(node => node.innerText.includes(label))
    }

    function findCheckbox({label}) {
      const labels = []
      document.querySelectorAll('label').forEach(node => labels.push(node))
      const checkboxId = labels.find(node => node.innerText.includes(label)).getAttribute('for')
      return document.getElementById(checkboxId)
    }

    function findButton({label}) {
      const buttons = []
      document.querySelectorAll('button').forEach(node => buttons.push(node))
      return buttons.find(node => node.innerText.includes(label))
    }

    async function isFormClosed(timeout = 300) {
      return waitFor(() => !document.body.innerText.includes('Update'), timeout)
    }

    QUnit.module('given a new latePolicy', newLatePolicyHooks => {
      let fetchLatePolicyStub
      let flashAlertSpy
      let onLatePolicyUpdate

      newLatePolicyHooks.beforeEach(async () => {
        fetchLatePolicyStub = sinon
          .stub(GradebookSettingsModalApi, 'fetchLatePolicy')
          .resolves({data: {latePolicy: NEW_LATE_POLICY}})
        flashAlertSpy = sinon.spy(FlashAlert, 'showFlashAlert')
        onLatePolicyUpdate = sinon.stub()
        await renderAndOpenComponent({onLatePolicyUpdate})
      })

      newLatePolicyHooks.afterEach(() => {
        ReactDOM.unmountComponentAtNode(fixtures)
        FlashAlert.destroyContainer()
        fetchLatePolicyStub.restore()
        flashAlertSpy.restore()
      })

      QUnit.module('given no form edits', () => {
        test('update button is not enabled', () => {
          const button = findButton({label: 'Update'})
          strictEqual(button.disabled, true)
        })

        test('given deselecting changes on the Late Policy Panel, update button is not enabled', () => {
          const checkbox = findCheckbox({
            label: 'Automatically apply grade for missing submissions'
          })
          checkbox.click()
          checkbox.click()

          const button = findButton({label: 'Update'})
          strictEqual(button.disabled, true)
        })

        QUnit.module('given the Advanced Panel', advancedPanelHooks => {
          advancedPanelHooks.beforeEach(() => findTab({label: 'Advanced'}).click())
          advancedPanelHooks.afterEach(() => findTab({label: 'Late Policies'}).click())

          test('given deselecting changes on the Advanced Panel update button is not enabled', () => {
            const checkbox = findCheckbox({label: 'Allow final grade override'})
            checkbox.click()
            checkbox.click()

            const button = findButton({label: 'Update'})
            strictEqual(button.disabled, true)
          })
        })
      })

      QUnit.module('given late policy form edits', latePolicyFormEditsHooks => {
        latePolicyFormEditsHooks.beforeEach(() => {
          findCheckbox({label: 'Automatically apply grade for missing submissions'}).click()
        })

        QUnit.module('given a successful response', successfulResponseHooks => {
          let createLatePolicyStub

          successfulResponseHooks.beforeEach(async () => {
            createLatePolicyStub = sinon
              .stub(GradebookSettingsModalApi, 'createLatePolicy')
              .resolves()
            findButton({label: 'Update'}).click()
            const isFlashMessageInDOM = () =>
              document.body.innerText.includes('Gradebook Settings updated')
            await waitFor(isFlashMessageInDOM)
          })

          successfulResponseHooks.afterEach(() => createLatePolicyStub.restore())

          test('onLatePolicyUpdate called', () => {
            const {callCount} = onLatePolicyUpdate
            strictEqual(callCount, 1)
          })

          test('a single flash message is present', () => {
            const {callCount} = flashAlertSpy
            strictEqual(callCount, 1)
          })

          test('a flash message with type success', () => {
            const {
              firstCall: {
                args: [{type}]
              }
            } = flashAlertSpy
            strictEqual(type, 'success')
          })

          test('the form is closed', async () => {
            strictEqual(await isFormClosed(), true)
          })
        })

        QUnit.module('given an error response', errorResponseHooks => {
          let createLatePolicyStub

          errorResponseHooks.beforeEach(() => {
            createLatePolicyStub = sinon
              .stub(GradebookSettingsModalApi, 'createLatePolicy')
              .rejects(new Error('Unauthorized'))
          })

          errorResponseHooks.afterEach(() => createLatePolicyStub.restore())

          QUnit.module('when update is clicked', hooks => {
            hooks.beforeEach(async () => {
              findButton({label: 'Update'}).click()
              const isFlashMessageInDOM = () =>
                document.body.innerText.includes('An error occurred while updating late policies')
              await waitFor(isFlashMessageInDOM)
            })

            test('onLatePolicyUpdate is not called', () => {
              const {callCount} = onLatePolicyUpdate
              strictEqual(callCount, 0)
            })

            test('a single flash message is present', () => {
              const {callCount} = flashAlertSpy
              strictEqual(callCount, 1)
            })

            test('a flash message with type error', () => {
              const {
                firstCall: {
                  args: [{type}]
                }
              } = flashAlertSpy
              strictEqual(type, 'error')
            })
          })
        })
      })
    })

    QUnit.module('given an existing latePolicy', existingLatePolicyHooks => {
      let fetchLatePolicyStub
      let flashAlertSpy
      let onLatePolicyUpdate

      existingLatePolicyHooks.beforeEach(async () => {
        fetchLatePolicyStub = sinon
          .stub(GradebookSettingsModalApi, 'fetchLatePolicy')
          .resolves({data: {latePolicy: EXISTING_LATE_POLICY}})
        flashAlertSpy = sinon.spy(FlashAlert, 'showFlashAlert')
        onLatePolicyUpdate = sinon.stub()
        await renderAndOpenComponent({onLatePolicyUpdate})
      })

      existingLatePolicyHooks.afterEach(() => {
        ReactDOM.unmountComponentAtNode(fixtures)
        FlashAlert.destroyContainer()
        fetchLatePolicyStub.restore()
        flashAlertSpy.restore()
      })

      QUnit.module('given no form edits', () => {
        test('update button is not enabled', () => {
          const button = findButton({label: 'Update'})
          strictEqual(button.disabled, true)
        })

        test('given deselecting changes on the Late Policy Panel, update button is not enabled', () => {
          const checkbox = findCheckbox({
            label: 'Automatically apply grade for missing submissions'
          })
          checkbox.click()
          checkbox.click()

          const button = findButton({label: 'Update'})
          strictEqual(button.disabled, true)
        })

        QUnit.module('given the Advanced Panel', advancedPanelHooks => {
          advancedPanelHooks.beforeEach(() => findTab({label: 'Advanced'}).click())
          advancedPanelHooks.afterEach(() => findTab({label: 'Late Policies'}).click())

          test('given deselecting changes on the Advanced Panel update button is not enabled', () => {
            const checkbox = findCheckbox({label: 'Allow final grade override'})
            checkbox.click()
            checkbox.click()

            const button = findButton({label: 'Update'})
            strictEqual(button.disabled, true)
          })
        })
      })

      QUnit.module('given late policy form edits', latePolicyFormEditsHooks => {
        latePolicyFormEditsHooks.beforeEach(() => {
          findCheckbox({label: 'Automatically apply grade for missing submissions'}).click()
        })

        QUnit.module(
          'given a successful response and given the update button is clicked',
          successfulResponseHooks => {
            let updateLatePolicyStub

            successfulResponseHooks.beforeEach(async () => {
              updateLatePolicyStub = sinon
                .stub(GradebookSettingsModalApi, 'updateLatePolicy')
                .resolves()
              findButton({label: 'Update'}).click()
              const isFlashMessageInDOM = () =>
                document.body.innerText.includes('Gradebook Settings updated')
              await waitFor(isFlashMessageInDOM)
            })

            successfulResponseHooks.afterEach(() => updateLatePolicyStub.restore())

            test('onLatePolicyUpdate called', () => {
              const {callCount} = onLatePolicyUpdate
              strictEqual(callCount, 1)
            })

            test('a single flash message is present', () => {
              const {callCount} = flashAlertSpy
              strictEqual(callCount, 1)
            })

            test('a flash message with type success', () => {
              const {
                firstCall: {
                  args: [{type}]
                }
              } = flashAlertSpy
              strictEqual(type, 'success')
            })

            test('the form is closed', async () => {
              strictEqual(await isFormClosed(), true)
            })
          }
        )
      })

      QUnit.module('given late policy form edits', latePolicyFormEditsHooks => {
        latePolicyFormEditsHooks.beforeEach(() => {
          findCheckbox({label: 'Automatically apply grade for missing submissions'}).click()
        })

        QUnit.module('given an error response and given update is clicked', errorResponseHooks => {
          let updateLatePolicyStub

          errorResponseHooks.beforeEach(async () => {
            updateLatePolicyStub = sinon
              .stub(GradebookSettingsModalApi, 'updateLatePolicy')
              .rejects()
            findButton({label: 'Update'}).click()
            const isFlashMessageInDOM = () =>
              document.body.innerText.includes('An error occurred while updating late policies')
            await waitFor(isFlashMessageInDOM)
          })

          errorResponseHooks.afterEach(() => updateLatePolicyStub.restore())

          test('onLatePolicyUpdate is not called', () => {
            const {callCount} = onLatePolicyUpdate
            strictEqual(callCount, 0)
          })

          test('a single flash message is present', () => {
            const {callCount} = flashAlertSpy
            strictEqual(callCount, 1)
          })

          test('a flash message with type error', () => {
            const {
              firstCall: {
                args: [{type}]
              }
            } = flashAlertSpy
            strictEqual(type, 'error')
          })
        })
      })
    })

    QUnit.module(
      'given a successful onChange response and edits to a Advanced Settings',
      advancedSettingsEditsHooks => {
        let fetchLatePolicyStub
        let flashAlertSpy

        advancedSettingsEditsHooks.beforeEach(() => {
          fetchLatePolicyStub = sinon
            .stub(GradebookSettingsModalApi, 'fetchLatePolicy')
            .resolves({data: {latePolicy: NEW_LATE_POLICY}})
          flashAlertSpy = sinon.spy(FlashAlert, 'showFlashAlert')
        })

        advancedSettingsEditsHooks.afterEach(() => {
          fetchLatePolicyStub.restore()
          flashAlertSpy.restore()
        })

        QUnit.module('given onChange resolves', onChangeResolvesHooks => {
          let onChange

          onChangeResolvesHooks.beforeEach(async () => {
            onChange = sinon.stub().resolves()
            const overrides = {
              defaultChecked: false,
              disabled: false,
              onChange
            }
            await renderAndOpenComponent({overrides})

            findTab({label: 'Advanced'}).click()
            findCheckbox({label: 'Allow final grade override'}).click()
            findButton({label: 'Update'}).click()
            const isFlashMessageInDOM = () =>
              document.body.innerText.includes('Gradebook Settings updated')
            await waitFor(isFlashMessageInDOM)
          })

          onChangeResolvesHooks.afterEach(() => {
            ReactDOM.unmountComponentAtNode(fixtures)
            FlashAlert.destroyContainer()
          })

          test('calls onChange', () => {
            const {callCount} = onChange
            strictEqual(callCount, 1)
          })

          test('a single flash message is present', () => {
            const {callCount} = flashAlertSpy
            strictEqual(callCount, 1)
          })

          test('a flash message with type success', () => {
            const {
              firstCall: {
                args: [{type}]
              }
            } = flashAlertSpy
            strictEqual(type, 'success')
          })

          test('the form is closed', async () => {
            strictEqual(await isFormClosed(), true)
          })
        })

        QUnit.module('given onChange rejects', onChangeRejectsHooks => {
          let onChange

          onChangeRejectsHooks.beforeEach(async () => {
            onChange = sinon.stub().rejects(new Error('Unknown Error'))
            const overrides = {
              defaultChecked: false,
              disabled: false,
              onChange
            }
            await renderAndOpenComponent({overrides})

            findTab({label: 'Advanced'}).click()
            findCheckbox({label: 'Allow final grade override'}).click()

            findButton({label: 'Update'}).click()
            const isFlashMessageInDOM = () =>
              document.body.innerText.includes('An error occurred while saving your settings')
            await waitFor(isFlashMessageInDOM)
          })

          onChangeRejectsHooks.afterEach(() => {
            ReactDOM.unmountComponentAtNode(fixtures)
            FlashAlert.destroyContainer()
          })

          test('calls onChange', () => {
            const {callCount} = onChange
            strictEqual(callCount, 1)
          })

          test('a single flash message is present', () => {
            const {callCount} = flashAlertSpy
            strictEqual(callCount, 1)
          })

          test('a flash message with type error', () => {
            const {
              firstCall: {
                args: [{type}]
              }
            } = flashAlertSpy
            strictEqual(type, 'error')
          })
        })
      }
    )

    QUnit.module('given changes to both Late Policy and Advanced', () => {
      async function editLatePolicyThenAdvancedSettings() {
        findCheckbox({label: 'Automatically apply grade for missing submissions'}).click()
        findTab({label: 'Advanced'}).click()
        findCheckbox({label: 'Allow final grade override'}).click()
        findButton({label: 'Update'}).click()
      }

      async function editAdvancedSettingsThenLatePolicy() {
        findTab({label: 'Advanced'}).click()
        findCheckbox({label: 'Allow final grade override'}).click()
        findTab({label: 'Late Policies'}).click()
        findCheckbox({label: 'Automatically apply grade for missing submissions'}).click()
        findButton({label: 'Update'}).click()
      }

      test('both promises can resolve successfully and close the form', async () => {
        const fetchLatePolicyStub = sinon
          .stub(GradebookSettingsModalApi, 'fetchLatePolicy')
          .resolves({data: {latePolicy: NEW_LATE_POLICY}})
        const createLatePolicyStub = sinon
          .stub(GradebookSettingsModalApi, 'createLatePolicy')
          .resolves()

        const onChange = sinon.stub().resolves()
        const overrides = {
          defaultChecked: false,
          disabled: false,
          onChange
        }
        await renderAndOpenComponent({overrides})

        editLatePolicyThenAdvancedSettings()
        const isFlashMessageInDOM = () =>
          document.body.innerText.includes('Gradebook Settings updated')
        await waitFor(isFlashMessageInDOM)

        strictEqual(await isFormClosed(), true)

        ReactDOM.unmountComponentAtNode(fixtures)
        FlashAlert.destroyContainer()
        createLatePolicyStub.restore()
        fetchLatePolicyStub.restore()
      })

      QUnit.module(
        'given an error response from creating a late policy',
        createLatePolicyErrorResponseHooks => {
          let fetchLatePolicyStub
          let createLatePolicyStub
          let onChange

          createLatePolicyErrorResponseHooks.beforeEach(async () => {
            fetchLatePolicyStub = sinon
              .stub(GradebookSettingsModalApi, 'fetchLatePolicy')
              .resolves({data: {latePolicy: NEW_LATE_POLICY}})
            createLatePolicyStub = sinon
              .stub(GradebookSettingsModalApi, 'createLatePolicy')
              .rejects(new Error('Unauthorized'))
            onChange = sinon.stub().resolves()
            const overrides = {
              defaultChecked: false,
              disabled: false,
              onChange
            }
            await renderAndOpenComponent({overrides})
          })

          createLatePolicyErrorResponseHooks.afterEach(() => {
            ReactDOM.unmountComponentAtNode(fixtures)
            FlashAlert.destroyContainer()
            createLatePolicyStub.restore()
            fetchLatePolicyStub.restore()
          })

          test('form is still submittable', async () => {
            await editLatePolicyThenAdvancedSettings()
            const isFlashMessageInDOM = () =>
              document.body.innerText.includes('An error occurred while updating late policies')
            await waitFor(isFlashMessageInDOM)

            const button = findButton({label: 'Update'})
            strictEqual(button.disabled, false)
          })

          test('the form data for Advanced Settings updates successfully', async () => {
            await editLatePolicyThenAdvancedSettings()
            const isFlashMessageInDOM = () =>
              document.body.innerText.includes('An error occurred while updating late policies')
            await waitFor(isFlashMessageInDOM)

            const checkbox = findCheckbox({label: 'Allow final grade override'})
            strictEqual(checkbox.checked, true)
          })

          test('the form data for Late Policies is still preset', async () => {
            // it is necessary to do things in this order because the panels
            // do not reflect previous changes when switching between tabs
            editAdvancedSettingsThenLatePolicy()
            const isFlashMessageInDOM = () =>
              document.body.innerText.includes('An error occurred while updating late policies')
            await waitFor(isFlashMessageInDOM)

            const checkbox = findCheckbox({
              label: 'Automatically apply grade for missing submissions'
            })
            strictEqual(checkbox.checked, true)
          })

          test('the form is not submittable when changes are cleared', async () => {
            // it is necessary to do things in this order because the panels
            // do not reflect previous changes when switching between tabs
            editAdvancedSettingsThenLatePolicy()
            const isFlashMessageInDOM = () =>
              document.body.innerText.includes('An error occurred while updating late policies')
            await waitFor(isFlashMessageInDOM)

            const checkbox = findCheckbox({
              label: 'Automatically apply grade for missing submissions'
            })
            checkbox.click()
            strictEqual(checkbox.checked, false)
          })
        }
      )

      QUnit.module('given Advanced Settings rejects', advancedSettingsOnChangeRejects => {
        let fetchLatePolicyStub
        let createLatePolicyStub
        let onChange

        advancedSettingsOnChangeRejects.beforeEach(async () => {
          fetchLatePolicyStub = sinon
            .stub(GradebookSettingsModalApi, 'fetchLatePolicy')
            .resolves({data: {latePolicy: NEW_LATE_POLICY}})
          createLatePolicyStub = sinon
            .stub(GradebookSettingsModalApi, 'createLatePolicy')
            .resolves()
          onChange = sinon.stub().rejects(new Error('Unknown Error'))
          const overrides = {
            defaultChecked: false,
            disabled: false,
            onChange
          }
          await renderAndOpenComponent({overrides})
        })

        advancedSettingsOnChangeRejects.afterEach(() => {
          ReactDOM.unmountComponentAtNode(fixtures)
          FlashAlert.destroyContainer()
          createLatePolicyStub.restore()
          fetchLatePolicyStub.restore()
        })

        test('the form data is still submittable', async () => {
          await editLatePolicyThenAdvancedSettings()
          const isFlashMessageInDOM = () =>
            document.body.innerText.includes('An error occurred while saving your settings')
          await waitFor(isFlashMessageInDOM)

          const button = findButton({label: 'Update'})
          strictEqual(button.disabled, false)
        })

        test('advanced settings are still present form', async () => {
          await editLatePolicyThenAdvancedSettings()
          const isFlashMessageInDOM = () =>
            document.body.innerText.includes('An error occurred while saving your settings')
          await waitFor(isFlashMessageInDOM)

          const checkbox = findCheckbox({label: 'Allow final grade override'})
          strictEqual(checkbox.checked, true)
        })

        test('the form data for Late Policies is still preset', async () => {
          // it is necessary to do things in this order because the panels
          // do not reflect previous changes when switching between tabs
          await editAdvancedSettingsThenLatePolicy()
          const isFlashMessageInDOM = () =>
            document.body.innerText.includes('An error occurred while saving your settings')
          await waitFor(isFlashMessageInDOM)

          const checkbox = findCheckbox({
            label: 'Automatically apply grade for missing submissions'
          })
          strictEqual(checkbox.checked, true)
        })

        test('the form is not submittable when changes are cleared', async () => {
          // it is necessary to do things in this order because the panels
          // do not reflect previous changes when switching between tabs
          await editLatePolicyThenAdvancedSettings()
          const isFlashMessageInDOM = () =>
            document.body.innerText.includes('An error occurred while saving your settings')
          await waitFor(isFlashMessageInDOM)
          findCheckbox({label: 'Allow final grade override'}).click()

          const button = findButton({label: 'Update'})
          strictEqual(button.disabled, false)
        })
      })
    })
  })
})

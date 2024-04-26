/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import moxios from 'moxios'
import {screen, render, fireEvent} from '@testing-library/react'
import storeCreator from '../store/store'
import actions from '../actions/developerKeysActions'
import InheritanceStateControl from '../InheritanceStateControl'

const sampleDeveloperKey = (defaults = {}) => {
  return {
    ...defaults,
    id: '1',
    workflow_state: 'on',
  }
}

const defaultProps = (developerKey, store, contextId) => {
  if (!store) {
    store = storeCreator({
      listDeveloperKeys: {
        list: [developerKey],
      },
    })
  }
  return {
    developerKey,
    ctx: {
      params: {
        contextId,
      },
    },
    store,
    actions,
  }
}

const renderInheritanceStateControl = (developerKey, store = false, contextId = '1') =>
  render(<InheritanceStateControl {...defaultProps(developerKey, store, contextId)} />)

describe('InheritanceStateControl', () => {
  let oldConfirmation = window.confirm
  let oldFeatures = {}

  beforeEach(() => {
    oldConfirmation = window.confirm
    window.confirm = jest.fn(() => true)
    window.ENV.FEATURES ||= {}
    oldFeatures = window.ENV.FEATURES

    moxios.install()
  })

  afterEach(() => {
    window.confirm = oldConfirmation
    window.ENV.FEATURES = oldFeatures

    moxios.uninstall()
  })

  it('uses the "off" state from the store for a siteadmin key', () => {
    const key = sampleDeveloperKey({
      developer_key_account_binding: {
        developer_key_id: '1',
        workflow_state: 'off',
        account_owns_binding: true,
      },
    })
    const {getByDisplayValue} = renderInheritanceStateControl(key, false, 'site_admin')
    const checkedBtn = getByDisplayValue('off')

    expect(checkedBtn.value).toBe('off')
  })

  it('uses the "on" state from the store for a siteadmin key', () => {
    const key = sampleDeveloperKey({
      developer_key_account_binding: {
        developer_key_id: '1',
        workflow_state: 'on',
        account_owns_binding: true,
      },
    })
    const {getByDisplayValue} = renderInheritanceStateControl(key, false, 'site_admin')
    const checkedBtn = getByDisplayValue('on')

    expect(checkedBtn.value).toBe('on')
  })

  it('uses the "off" state from the store', () => {
    const key = sampleDeveloperKey({
      developer_key_account_binding: {
        developer_key_id: '1',
        workflow_state: 'off',
        account_owns_binding: true,
      },
    })
    const {getByRole} = renderInheritanceStateControl(key)
    const checkedBtn = getByRole('checkbox')

    expect(checkedBtn.checked).toBe(false)
  })

  it('uses the "on" state from the store', () => {
    const key = sampleDeveloperKey({
      developer_key_account_binding: {
        developer_key_id: '1',
        workflow_state: 'on',
        account_owns_binding: true,
      },
    })
    const {getByRole} = renderInheritanceStateControl(key)
    const checkedBtn = getByRole('checkbox')

    expect(checkedBtn.checked).toBe(true)
  })

  it('renders "off" if "allow" is set as the workflow state for root account', () => {
    const key = sampleDeveloperKey()
    const {getByRole} = renderInheritanceStateControl(key)
    const checkedBtn = getByRole('checkbox')

    expect(checkedBtn.checked).toBe(false)
  })

  it('updates the state when the RadioInput is clicked', () => {
    const key = sampleDeveloperKey({
      developer_key_account_binding: {
        developer_key_id: '1',
        workflow_state: 'on',
        account_owns_binding: true,
      },
    })
    const store = storeCreator({
      listDeveloperKeys: {
        list: [key],
      },
    })

    renderInheritanceStateControl(key, store, 'site_admin')

    const item = screen.getByText('Off')

    fireEvent.click(item)

    const updatedDevKey = store.getState().listDeveloperKeys.list[0]

    expect(updatedDevKey.developer_key_account_binding.workflow_state).toBe('off')
  })

  it('updates the state when the Checkbox is clicked', () => {
    const key = sampleDeveloperKey({
      developer_key_account_binding: {
        developer_key_id: '1',
        workflow_state: 'on',
        account_owns_binding: true,
      },
    })
    const store = storeCreator({
      listDeveloperKeys: {
        list: [key],
      },
    })

    renderInheritanceStateControl(key, store)

    const item = document.querySelector('input[type="checkbox"]:checked')

    fireEvent.click(item)

    const updatedDevKey = store.getState().listDeveloperKeys.list[0]

    expect(updatedDevKey.developer_key_account_binding.workflow_state).toBe('off')
  })

  it('does nothing if cancel is clicked in the confirmation modal', () => {
    const key = sampleDeveloperKey({
      developer_key_account_binding: {
        developer_key_id: '1',
        workflow_state: 'on',
        account_owns_binding: true,
      },
    })
    const store = storeCreator({
      listDeveloperKeys: {
        list: [key],
      },
    })

    const {getByRole} = renderInheritanceStateControl(key, store)
    const item = getByRole('checkbox')

    fireEvent.change(item, {target: {checked: true}})

    const devKeyFromStore = store.getState().listDeveloperKeys.list[0]

    expect(devKeyFromStore.developer_key_account_binding.workflow_state).toBe('on')
  })

  const rootAccountCTX = {
    params: {
      contextId: '1',
    },
  }

  const siteAdminCTX = {
    params: {
      contextId: 'site_admin',
    },
  }

  const mockDevKey = (workflowState, isOwnedByAccount, inheritedTo) => {
    return {
      id: '10000000000123',
      developer_key_account_binding: {
        workflow_state: workflowState || 'off',
        account_owns_binding: isOwnedByAccount || false,
      },
      inherited_to: inheritedTo,
    }
  }

  const componentNode = (key, context = rootAccountCTX) => {
    const {container} = render(
      <InheritanceStateControl
        developerKey={key}
        ctx={context}
        store={{dispatch: () => {}}}
        actions={{setBindingWorkflowState: () => {}}}
      />
    )
    return container
  }

  it('disables the checkbox if the account does not own the binding and it is set', () => {
    const checkbox = componentNode(mockDevKey('off')).querySelector('input[type="checkbox"]')

    expect(checkbox.disabled).toBe(true)
  })

  it('disabled the checkbox if the account does not own the binding and it is not set and the account is a child account', () => {
    const checkbox = componentNode(mockDevKey('allow', false, 'child_account')).querySelector(
      'input[type="checkbox"]'
    )

    expect(checkbox.disabled).toBe(true)
  })

  it('enables the radio group if the account does not own the binding and it is not set and the account is not a child account', () => {
    const radioGroup = componentNode(mockDevKey('allow'), siteAdminCTX).querySelector(
      'input[type="radio"]'
    )

    expect(radioGroup.disabled).toBeFalsy()
  })

  it('enables the radio group if the account does own the binding', () => {
    const radioGroup = componentNode(mockDevKey('on', true)).querySelector('input[type="checkbox"]')

    expect(radioGroup.disabled).toBeFalsy()
  })

  it('the correct state for the developer key for siteadmin', () => {
    const offRadioInput = componentNode(mockDevKey(), siteAdminCTX).querySelector(
      'input[value="off"]'
    )

    expect(offRadioInput.checked).toBe(true)
  })

  it('the correct state for the developer key that is off', () => {
    const toggleSwitch = componentNode(mockDevKey()).querySelector('input[type="checkbox"]')

    expect(toggleSwitch.checked).toBe(false)
  })

  it('the correct state for a developer key that is on', () => {
    const toggleSwitch = componentNode(mockDevKey('on')).querySelector('input[type="checkbox"]')

    expect(toggleSwitch.checked).toBe(true)
  })

  it('renders "allow" if no binding is sent only for site_admin', () => {
    const modifiedKey = mockDevKey()
    modifiedKey.developer_key_account_binding = undefined
    const allowRadioInput = componentNode(modifiedKey, siteAdminCTX).querySelector(
      'input[value="allow"]'
    )

    expect(allowRadioInput.checked).toBe(true)
  })

  it('renders an "on" option for siteadmin keys', () => {
    expect(componentNode({id: '123'}, siteAdminCTX).querySelector('input[value="on"]')).toBeTruthy()
  })

  it('renders an "off" option for siteadmin keys', () => {
    expect(
      componentNode({id: '123'}, siteAdminCTX).querySelector('input[value="off"]')
    ).toBeTruthy()
  })

  it('renders a toggle switch for non-siteadmin keys', () => {
    expect(componentNode({id: '123'}).querySelector('input[type="checkbox"]')).toBeTruthy()
  })

  it('renders an "allow" option only for site_admin', () => {
    expect(
      componentNode(mockDevKey(), siteAdminCTX).querySelector('input[value="allow"]')
    ).toBeTruthy()
  })

  it('do not render an "allow" option only for root-account', () => {
    expect(
      componentNode(mockDevKey(), rootAccountCTX).querySelector('input[value="allow"]')
    ).toBeFalsy()
  })

  it('renders "allow" if "allow" is set as the workflow state for site admin', () => {
    const allowRadioInput = componentNode(mockDevKey('allow'), siteAdminCTX).querySelector(
      'input[value="allow"]'
    )

    expect(allowRadioInput.checked).toBe(true)
  })
})

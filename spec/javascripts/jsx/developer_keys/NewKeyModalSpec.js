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
import {mount, shallow} from 'enzyme'
import DeveloperKeyModal from 'jsx/developer_keys/NewKeyModal'
import $ from 'compiled/jquery.rails_flash_notifications'

QUnit.module('NewKeyModal')

const selectedScopes = [
  "url:POST|/api/v1/accounts/:account_id/account_notifications",
  "url:PUT|/api/v1/accounts/:account_id/account_notifications/:id"
]

const fakeActions = {
  createOrEditDeveloperKey: () => {},
  editDeveloperKey: () => {},
  ltiKeysSetDisabledPlacements: () => {},
  ltiKeysSetEnabledScopes: () => {}
}

const developerKey = {
  access_token_count: 77,
  account_name: 'bob account',
  api_key: 'rYcJ7LnUbSAuxiMh26tXTSkaYWyfRPh2lr6FqTLqx0FRsmv44EVZ2yXC8Rgtabc3',
  created_at: '2018-02-09T20:36:50Z',
  email: 'bob@myemail.com',
  icon_url: 'http://my_image.com',
  id: '10000000000004',
  last_used_at: '2018-06-07T20:36:50Z',
  name: 'Dev Key Name',
  notes: 'all the notas',
  redirect_uri: 'http://my_redirect_uri.com',
  redirect_uris: '',
  user_id: '53532',
  user_name: 'billy bob',
  vendor_code: 'b3w9w9bf',
  workflow_state: 'active',
  test_cluster_only: false
}

const createLtiKeyState = {
  isLtiKey: false,
  customizing: false,
  toolConfiguration: {},
  enabledScopes: ['https://www.test.com/lineitem'],
  disabledPlacements: ['account_navigation'],
}

const createDeveloperKeyState = {
  developerKeyCreateOrEditSuccessful: false,
  developerKeyCreateOrEditFailed: false,
  developerKeyModalOpen: true,
  developerKey: {id: 22}
}

const editDeveloperKeyState = {
  developerKeyCreateOrEditSuccessful: false,
  developerKeyCreateOrEditFailed: false,
  developerKeyModalOpen: true,
  developerKey
}

const closedDeveloperKeyState = {
  developerKeyCreateOrEditSuccessful: false,
  developerKeyCreateOrEditFailed: false,
  developerKeyModalOpen: false,
  developerKey
}

const listDeveloperKeyScopesState = {
  availableScopes: {},
  listDeveloperKeyScopesPending: true
}

function modalMountNode() {
  return document.querySelector('#fixtures')
}

test('it opens the modal if isOpen prop is true', () => {
  const wrapper = shallow(
    <DeveloperKeyModal
      createLtiKeyState={createLtiKeyState}
      availableScopes={{}}
      availableScopesPending={false}
      closeModal={() => {}}
      createOrEditDeveloperKeyState={createDeveloperKeyState}
      actions={fakeActions}
      store={{dispatch: () => {}}}
      mountNode={modalMountNode}
      selectedScopes={selectedScopes}
    />
  )
  equal(wrapper.find('Modal').prop('open'), true)
})

test('it closes the modal if isOpen prop is false', () => {
  const wrapper = shallow(
    <DeveloperKeyModal
      createLtiKeyState={createLtiKeyState}
      availableScopes={{}}
      availableScopesPending={false}
      closeModal={() => {}}
      createOrEditDeveloperKeyState={closedDeveloperKeyState}
      actions={fakeActions}
      store={{dispatch: () => {}}}
      mountNode={modalMountNode}
      selectedScopes={selectedScopes}
    />
  )
  equal(wrapper.find('Modal').prop('open'), false)
})

test('it sends the contents of the form saving', () => {
  const createOrEditSpy = sinon.spy()
  const dispatchSpy = sinon.spy()

  const fakeActions = {
    createOrEditDeveloperKey: createOrEditSpy
  }
  const fakeStore = {
    dispatch: dispatchSpy
  }
  const developerKey2 = Object.assign({}, developerKey, { require_scopes: true, scopes: ['test'], test_cluster_only: true })
  const editDeveloperKeyState2 = Object.assign({}, editDeveloperKeyState, { developerKey: developerKey2 })

  const wrapper = mount(
    <DeveloperKeyModal
      createLtiKeyState={createLtiKeyState}
      availableScopes={{}}
      availableScopesPending={false}
      closeModal={() => {}}
      createOrEditDeveloperKeyState={editDeveloperKeyState2}
      listDeveloperKeyScopesState={listDeveloperKeyScopesState}
      actions={fakeActions}
      store={fakeStore}
      mountNode={modalMountNode}
      selectedScopes={selectedScopes}
    />
  )

  wrapper.instance().submitForm()

  const [[sentFormData]] = createOrEditSpy.args

  equal(sentFormData.get('developer_key[name]'), developerKey.name)
  equal(sentFormData.get('developer_key[email]'), developerKey.email)
  equal(sentFormData.get('developer_key[redirect_uri]'), developerKey.redirect_uri)
  equal(sentFormData.get('developer_key[redirect_uris]'), developerKey.redirect_uris)
  equal(sentFormData.get('developer_key[vendor_code]'), developerKey.vendor_code)
  equal(sentFormData.get('developer_key[icon_url]'), developerKey.icon_url)
  equal(sentFormData.get('developer_key[notes]'), developerKey.notes)
  equal(sentFormData.get('developer_key[require_scopes]'), 'true')
  equal(sentFormData.get('developer_key[test_cluster_only]'), 'true')

  wrapper.unmount()
})

test('sends form content without scopes and require_scopes set to false when not require_scopes', () => {
  const createOrEditSpy = sinon.spy()
  const dispatchSpy = sinon.spy()

  const fakeActions = {
    createOrEditDeveloperKey: createOrEditSpy
  }
  const fakeStore = {
    dispatch: dispatchSpy
  }

  const wrapper = mount(
    <DeveloperKeyModal
      createLtiKeyState={createLtiKeyState}
      availableScopes={{}}
      availableScopesPending={false}
      closeModal={() => {}}
      createOrEditDeveloperKeyState={editDeveloperKeyState}
      listDeveloperKeyScopesState={listDeveloperKeyScopesState}
      actions={fakeActions}
      store={fakeStore}
      mountNode={modalMountNode}
      selectedScopes={selectedScopes}
    />
  )

  wrapper.instance().submitForm()

  const [[sentFormData]] = createOrEditSpy.args

  equal(sentFormData.get('developer_key[name]'), developerKey.name)
  equal(sentFormData.get('developer_key[email]'), developerKey.email)
  equal(sentFormData.get('developer_key[redirect_uri]'), developerKey.redirect_uri)
  equal(sentFormData.get('developer_key[redirect_uris]'), developerKey.redirect_uris)
  equal(sentFormData.get('developer_key[vendor_code]'), developerKey.vendor_code)
  equal(sentFormData.get('developer_key[icon_url]'), developerKey.icon_url)
  equal(sentFormData.get('developer_key[notes]'), developerKey.notes)
  equal(sentFormData.get('developer_key[require_scopes]'), 'false')
  equal(sentFormData.get('developer_key[test_cluster_only]'), 'false')

  wrapper.unmount()
})

test('it adds each selected scope to the form data', () => {
  const createOrEditSpy = sinon.spy()
  const dispatchSpy = sinon.spy()
  const fakeActions = { createOrEditDeveloperKey: createOrEditSpy }
  const fakeStore = { dispatch: dispatchSpy }
  const developerKey2 = Object.assign({}, developerKey, { require_scopes: true, scopes: ['test'] })
  const editDeveloperKeyState2 = Object.assign({}, editDeveloperKeyState, { developerKey: developerKey2 })
  const wrapper = mount(
    <DeveloperKeyModal
      createLtiKeyState={createLtiKeyState}
      availableScopes={{}}
      availableScopesPending={false}
      closeModal={() => {}}
      createOrEditDeveloperKeyState={editDeveloperKeyState2}
      listDeveloperKeyScopesState={listDeveloperKeyScopesState}
      actions={fakeActions}
      store={fakeStore}
      mountNode={modalMountNode}
      selectedScopes={selectedScopes}
    />
  )
  wrapper.instance().submitForm()
  const [[sentFormData]] = createOrEditSpy.args
  deepEqual(sentFormData.getAll('developer_key[scopes][]'), selectedScopes)

  wrapper.unmount()
})

test('it removes testClusterOnly from the form data if it is undefined', () => {
  const createOrEditSpy = sinon.spy()
  const dispatchSpy = sinon.spy()
  const fakeActions = { createOrEditDeveloperKey: createOrEditSpy }
  const fakeStore = { dispatch: dispatchSpy }
  const developerKey2 = Object.assign({}, developerKey, { require_scopes: true, scopes: ['test'] })
  delete developerKey2.test_cluster_only
  const editDeveloperKeyState2 = Object.assign({}, editDeveloperKeyState, { developerKey: developerKey2 })
  const wrapper = mount(
    <DeveloperKeyModal
      createLtiKeyState={createLtiKeyState}
      availableScopes={{}}
      availableScopesPending={false}
      closeModal={() => {}}
      createOrEditDeveloperKeyState={editDeveloperKeyState2}
      listDeveloperKeyScopesState={listDeveloperKeyScopesState}
      actions={fakeActions}
      store={fakeStore}
      mountNode={modalMountNode}
      selectedScopes={selectedScopes}
    />
  )
  wrapper.instance().submitForm()
  const [[sentFormData]] = createOrEditSpy.args
  notOk(sentFormData.has('test_cluster_only'))

  wrapper.unmount()
})

test('flashes an error if no scopes are selected', () => {
  const flashStub = sinon.stub($, 'flashError')
  const createOrEditSpy = sinon.spy()
  const dispatchSpy = sinon.spy()
  const fakeActions = { createOrEditDeveloperKey: createOrEditSpy }
  const fakeStore = { dispatch: dispatchSpy }
  const developerKey2 = Object.assign({}, developerKey, { require_scopes: true, scopes: [] })
  const editDeveloperKeyState2 = Object.assign({}, editDeveloperKeyState, { developerKey: developerKey2 })
  const wrapper = mount(
    <DeveloperKeyModal
      createLtiKeyState={createLtiKeyState}
      availableScopes={{}}
      availableScopesPending={false}
      closeModal={() => {}}
      createOrEditDeveloperKeyState={editDeveloperKeyState2}
      listDeveloperKeyScopesState={listDeveloperKeyScopesState}
      actions={fakeActions}
      store={fakeStore}
      mountNode={modalMountNode}
      selectedScopes={[]}
    />
  )
  wrapper.instance().submitForm()
  ok(flashStub.calledWith('At least one scope must be selected.'))
  flashStub.restore()

  wrapper.unmount()
})

test('allows saving if the key previously had scopes', () => {
  const flashStub = sinon.stub($, 'flashError')
  const dispatchSpy = sinon.spy()
  const fakeStore = { dispatch: dispatchSpy }
  const keyWithScopes = Object.assign({}, developerKey, { require_scopes: true, scopes: selectedScopes })
  const editKeyWithScopesState = Object.assign({}, editDeveloperKeyState, { developerKey: keyWithScopes })
  const wrapper = mount(
    <DeveloperKeyModal
      createLtiKeyState={createLtiKeyState}
      availableScopes={{}}
      availableScopesPending={false}
      createOrEditDeveloperKeyState={editKeyWithScopesState}
      listDeveloperKeyScopesState={listDeveloperKeyScopesState}
      actions={fakeActions}
      store={fakeStore}
      mountNode={modalMountNode}
      selectedScopes={selectedScopes}
    />
  )

  wrapper.instance().submitForm()
  notOk(flashStub.called)
  flashStub.restore()
  wrapper.unmount()
})

test('renders the LTI footer if "ltiKey" is true', () => {
  window.ENV = window.ENV || {}
  window.ENV.validLtiScopes = {}
  window.ENV.validLtiPlacements = []

  const createLtiKeyStateOn = {
    isLtiKey: true,
    customizing: true,
    toolConfiguration: {},
    validScopes: [],
    validPlacements: []
  }

  const wrapper = mount(
    <DeveloperKeyModal
      createLtiKeyState={createLtiKeyStateOn}
      availableScopes={{}}
      availableScopesPending={false}
      closeModal={() => {}}
      createOrEditDeveloperKeyState={createDeveloperKeyState}
      actions={fakeActions}
      store={{dispatch: () => {}}}
      mountNode={modalMountNode}
      selectedScopes={selectedScopes}
    />
  )

  ok(wrapper.instance().modalFooter().props.customizing)
  wrapper.unmount()
  window.ENV.validLtiScopes = undefined
  window.ENV.validLtiPlacements = undefined
})

test('renders the non LTI footer if "ltiKey" is false', () => {
  const wrapper = mount(
    <DeveloperKeyModal
      createLtiKeyState={createLtiKeyState}
      availableScopes={{}}
      availableScopesPending={false}
      closeModal={() => {}}
      createOrEditDeveloperKeyState={createDeveloperKeyState}
      actions={fakeActions}
      store={{dispatch: () => {}}}
      mountNode={modalMountNode}
      selectedScopes={selectedScopes}
    />
  )

  notOk(wrapper.instance().modalFooter().props.customizing)
  wrapper.unmount()
})

test('clears the lti key state when modal is closed', () => {
  const ltiStub = sinon.spy()
  const actions = Object.assign(fakeActions, {
    developerKeysModalClose: () => {},
    ltiKeysSetCustomizing: () => {},
    resetLtiState: ltiStub
  })

  const wrapper = mount(
    <DeveloperKeyModal
      createLtiKeyState={createLtiKeyState}
      availableScopes={{}}
      availableScopesPending={false}
      closeModal={() => {}}
      createOrEditDeveloperKeyState={createDeveloperKeyState}
      actions={actions}
      store={{dispatch: () => {}}}
      mountNode={modalMountNode}
      selectedScopes={selectedScopes}
    />
  )
  wrapper.instance().closeModal()
  ok(ltiStub.called)
  wrapper.unmount()
})

test('saves customizations', () => {
  const ltiStub = sinon.spy()
  const actions = Object.assign(fakeActions, {
    ltiKeysUpdateCustomizations: ltiStub
  })

  const wrapper = mount(
    <DeveloperKeyModal
      createLtiKeyState={createLtiKeyState}
      availableScopes={{}}
      availableScopesPending={false}
      closeModal={() => {}}
      createOrEditDeveloperKeyState={createDeveloperKeyState}
      actions={actions}
      store={{dispatch: () => {}}}
      mountNode={modalMountNode}
      selectedScopes={selectedScopes}
    />
  )
  wrapper.instance().saveCustomizations()
  ok(ltiStub.calledWith(['https://www.test.com/lineitem'], ['account_navigation'], 22, {}, null))
  wrapper.unmount()
})

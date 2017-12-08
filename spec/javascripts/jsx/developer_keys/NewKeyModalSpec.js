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
import {mount, shallow} from 'old-enzyme-2.x-you-need-to-upgrade-this-spec-to-enzyme-3.x-by-importing-just-enzyme'
import DeveloperKeyModal from 'jsx/developer_keys/NewKeyModal'
import $ from 'compiled/jquery.rails_flash_notifications'

QUnit.module('NewKeyModal')

const selectedScopes = [
  "url:POST|/api/v1/accounts/:account_id/account_notifications",
  "url:PUT|/api/v1/accounts/:account_id/account_notifications/:id"
]

const fakeActions = {
  createOrEditDeveloperKey: () => {},
  editDeveloperKey: () => {}
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

const createDeveloperKeyState = {
  developerKeyCreateOrEditSuccessful: false,
  developerKeyCreateOrEditFailed: false,
  developerKeyModalOpen: true,
  developerKey: undefined
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
  ok(wrapper.find('Modal Heading [level="h2"]').exists())
})

test('it closes the modal if isOpen prop is false', () => {
  const wrapper = shallow(
    <DeveloperKeyModal
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

test('it dismisses the modal when the "cancel" button is pressed', () => {
  const closeModalSpy = sinon.spy()

  const fakeActions = {
    createOrEditDeveloperKey: () => {},
    developerKeysModalClose: closeModalSpy,
    editDeveloperKey: () => {}
  }

  const wrapper = shallow(
    <DeveloperKeyModal
      availableScopes={{}}
      availableScopesPending={false}
      createOrEditDeveloperKeyState={createDeveloperKeyState}
      actions={fakeActions}
      store={{dispatch: () => {}}}
      mountNode={modalMountNode}
      selectedScopes={selectedScopes}
    />
  )
  const cancelButton = wrapper.find('Button').filterWhere(n => n.prop('children') === 'Cancel')
  cancelButton.simulate('click')

  ok(closeModalSpy.called)
})

test('clear the active key when the cancel button is closed', () => {
  const setKeySpy = sinon.spy()

  const fakeActions = {
    createOrEditDeveloperKey: () => {},
    developerKeysModalClose: () => {},
    editDeveloperKey: setKeySpy
  }

  const wrapper = shallow(
    <DeveloperKeyModal
      availableScopes={{}}
      availableScopesPending={false}
      createOrEditDeveloperKeyState={createDeveloperKeyState}
      actions={fakeActions}
      store={{dispatch: () => {}}}
      mountNode={modalMountNode}
      selectedScopes={selectedScopes}
    />
  )
  const cancelButton = wrapper.find('Button').filterWhere(n => n.prop('children') === 'Cancel')
  cancelButton.simulate('click')

  ok(setKeySpy.called)
  equal(setKeySpy.args[0].length, 0)
})

test('it uses the create URL if a key is being created', () => {
  const createOrEditSpy = sinon.spy()
  const dispatchSpy = sinon.spy()

  const fakeActions = {
    createOrEditDeveloperKey: createOrEditSpy,
    developerKeysModalClose: () => {}
  }
  const fakeStore = {
    dispatch: dispatchSpy
  }
  const ctx = {
    params: {
      contextId: 23
    }
  }

  const wrapper = shallow(
    <DeveloperKeyModal
      availableScopes={{}}
      availableScopesPending={false}
      closeModal={() => {}}
      createOrEditDeveloperKeyState={createDeveloperKeyState}
      actions={fakeActions}
      store={fakeStore}
      ctx={ctx}
      mountNode={modalMountNode}
      selectedScopes={selectedScopes}
    />
  )

  const saveButton = wrapper.find('Button').filterWhere(n => n.prop('children') === 'Save Key')
  saveButton.simulate('click')

  const url = createOrEditSpy.args[0][1]
  equal(url, '/api/v1/accounts/23/developer_keys')
})

test('it uses POST if a key is being created', () => {
  const createOrEditSpy = sinon.spy()
  const dispatchSpy = sinon.spy()

  const fakeActions = {
    createOrEditDeveloperKey: createOrEditSpy,
    developerKeysModalClose: () => {}
  }
  const fakeStore = {
    dispatch: dispatchSpy
  }
  const ctx = {
    params: {
      contextId: 23
    }
  }

  const wrapper = shallow(
    <DeveloperKeyModal
      availableScopes={{}}
      availableScopesPending={false}
      closeModal={() => {}}
      createOrEditDeveloperKeyState={createDeveloperKeyState}
      actions={fakeActions}
      store={fakeStore}
      ctx={ctx}
      mountNode={modalMountNode}
      selectedScopes={selectedScopes}
    />
  )

  const saveButton = wrapper.find('Button').filterWhere(n => n.prop('children') === 'Save Key')
  saveButton.simulate('click')

  const method = createOrEditSpy.args[0][2]
  equal(method, 'post')
})

test('it uses the edit URL if a key is being edited', () => {
  const createOrEditSpy = sinon.spy()
  const dispatchSpy = sinon.spy()

  const fakeActions = {
    createOrEditDeveloperKey: createOrEditSpy,
    developerKeysModalClose: () => {}
  }
  const fakeStore = {
    dispatch: dispatchSpy
  }

  const wrapper = shallow(
    <DeveloperKeyModal
      availableScopes={{}}
      availableScopesPending={false}
      closeModal={() => {}}
      createOrEditDeveloperKeyState={editDeveloperKeyState}
      actions={fakeActions}
      store={fakeStore}
      mountNode={modalMountNode}
      selectedScopes={selectedScopes}
    />
  )

  const saveButton = wrapper.find('Button').filterWhere(n => n.prop('children') === 'Save Key')
  saveButton.simulate('click')

  const url = createOrEditSpy.args[0][1]
  equal(url, `/api/v1/developer_keys/${developerKey.id}`)
})

test('it uses PUT if a key is being edited', () => {
  const createOrEditSpy = sinon.spy()
  const dispatchSpy = sinon.spy()

  const fakeActions = {
    createOrEditDeveloperKey: createOrEditSpy
  }
  const fakeStore = {
    dispatch: dispatchSpy
  }

  const wrapper = shallow(
    <DeveloperKeyModal
      availableScopes={{}}
      availableScopesPending={false}
      closeModal={() => {}}
      createOrEditDeveloperKeyState={editDeveloperKeyState}
      actions={fakeActions}
      store={fakeStore}
      mountNode={modalMountNode}
      selectedScopes={selectedScopes}
    />
  )

  const saveButton = wrapper.find('Button').filterWhere(n => n.prop('children') === 'Save Key')
  saveButton.simulate('click')

  ok(createOrEditSpy.called)
  const method = createOrEditSpy.args[0][2]
  equal(method, `put`)
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
  const developerKey2 = Object.assign({}, developerKey, { require_scopes: true, scopes: ['test'] })
  const editDeveloperKeyState2 = Object.assign({}, editDeveloperKeyState, { developerKey: developerKey2 })

  const wrapper = mount(
    <DeveloperKeyModal
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

  wrapper.node.submitForm()

  const [[sentFormData]] = createOrEditSpy.args

  equal(sentFormData.get('developer_key[name]'), developerKey.name)
  equal(sentFormData.get('developer_key[email]'), developerKey.email)
  equal(sentFormData.get('developer_key[redirect_uri]'), developerKey.redirect_uri)
  equal(sentFormData.get('developer_key[redirect_uris]'), developerKey.redirect_uris)
  equal(sentFormData.get('developer_key[vendor_code]'), developerKey.vendor_code)
  equal(sentFormData.get('developer_key[icon_url]'), developerKey.icon_url)
  equal(sentFormData.get('developer_key[notes]'), developerKey.notes)
  equal(sentFormData.get('developer_key[require_scopes]'), 'true')
  equal(sentFormData.get('developer_key[test_cluster_only]'), 'false')

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

  wrapper.node.submitForm()

  const [[sentFormData]] = createOrEditSpy.args

  equal(sentFormData.get('developer_key[name]'), developerKey.name)
  equal(sentFormData.get('developer_key[email]'), developerKey.email)
  equal(sentFormData.get('developer_key[redirect_uri]'), developerKey.redirect_uri)
  equal(sentFormData.get('developer_key[redirect_uris]'), developerKey.redirect_uris)
  equal(sentFormData.get('developer_key[vendor_code]'), developerKey.vendor_code)
  equal(sentFormData.get('developer_key[icon_url]'), developerKey.icon_url)
  equal(sentFormData.get('developer_key[notes]'), developerKey.notes)
  equal(sentFormData.get('developer_key[require_scopes]'), 'false')

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
  wrapper.node.submitForm()
  const [[sentFormData]] = createOrEditSpy.args
  deepEqual(sentFormData.getAll('developer_key[scopes][]'), selectedScopes)

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
  wrapper.node.submitForm()
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

  wrapper.node.submitForm()
  notOk(flashStub.called)
  flashStub.restore()
  wrapper.unmount()
})

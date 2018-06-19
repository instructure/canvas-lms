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
import DeveloperKeyModal from 'jsx/developer_keys/DeveloperKeyModal'
import $ from 'jquery'

QUnit.module('DeveloperKeyModal', {
  teardown() {
    $('#fixtures').empty()
  }
})

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
  workflow_state: 'active'
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

function modalMountNode() {
  return document.querySelector('#fixtures')
}

test('it opens the modal if isOpen prop is true', () => {
  const fakeActions = {
    createOrEditDeveloperKey: () => {},
    setEditingDeveloperKey: () => {}
  }

  const wrapper = shallow(
    <DeveloperKeyModal
      closeModal={() => {}}
      createOrEditDeveloperKeyState={createDeveloperKeyState}
      actions={fakeActions}
      store={{dispatch: () => {}}}
      mountNode={modalMountNode}
    />
  )
  equal(wrapper.find('Modal').prop('open'), true)
  ok(wrapper.find('Modal Heading [level="h4"]').exists())
})

test('it closes the modal if isOpen prop is false', () => {
  const fakeActions = {
    createOrEditDeveloperKey: () => {},
    setEditingDeveloperKey: () => {}
  }

  const wrapper = shallow(
    <DeveloperKeyModal
      closeModal={() => {}}
      createOrEditDeveloperKeyState={closedDeveloperKeyState}
      actions={fakeActions}
      store={{dispatch: () => {}}}
      mountNode={modalMountNode}
    />
  )
  equal(wrapper.find('Modal').prop('open'), false)
})

test('it dismisses the modal when the "cancel" button is pressed', () => {
  const closeModalSpy = sinon.spy()

  const fakeActions = {
    createOrEditDeveloperKey: () => {},
    developerKeysModalClose: closeModalSpy,
    setEditingDeveloperKey: () => {}
  }

  const wrapper = shallow(
    <DeveloperKeyModal
      createOrEditDeveloperKeyState={createDeveloperKeyState}
      actions={fakeActions}
      store={{dispatch: () => {}}}
      mountNode={modalMountNode}
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
    setEditingDeveloperKey: setKeySpy
  }

  const wrapper = shallow(
    <DeveloperKeyModal
      createOrEditDeveloperKeyState={createDeveloperKeyState}
      actions={fakeActions}
      store={{dispatch: () => {}}}
      mountNode={modalMountNode}
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
      closeModal={() => {}}
      createOrEditDeveloperKeyState={createDeveloperKeyState}
      actions={fakeActions}
      store={fakeStore}
      ctx={ctx}
      mountNode={modalMountNode}
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
      closeModal={() => {}}
      createOrEditDeveloperKeyState={createDeveloperKeyState}
      actions={fakeActions}
      store={fakeStore}
      ctx={ctx}
      mountNode={modalMountNode}
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
      closeModal={() => {}}
      createOrEditDeveloperKeyState={editDeveloperKeyState}
      actions={fakeActions}
      store={fakeStore}
      mountNode={modalMountNode}
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
      closeModal={() => {}}
      createOrEditDeveloperKeyState={editDeveloperKeyState}
      actions={fakeActions}
      store={fakeStore}
      mountNode={modalMountNode}
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

  const wrapper = mount(
    <DeveloperKeyModal
      closeModal={() => {}}
      createOrEditDeveloperKeyState={editDeveloperKeyState}
      actions={fakeActions}
      store={fakeStore}
      mountNode={modalMountNode}
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
})

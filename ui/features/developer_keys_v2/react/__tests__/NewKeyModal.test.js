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
import DeveloperKeyModal from '../NewKeyModal'
import $ from '@canvas/rails-flash-notifications'

let oldEnv

beforeEach(() => {
  oldEnv = window.ENV
  window.ENV = {
    ...window.ENV,
    validLtiPlacements: [],
    validLtiScopes: {}
  }
})

afterEach(() => {
  window.ENV = oldEnv
})

afterEach(() => jest.restoreAllMocks())

const selectedScopes = [
  'url:POST|/api/v1/accounts/:account_id/account_notifications',
  'url:PUT|/api/v1/accounts/:account_id/account_notifications/:id'
]

const fakeActions = {
  createOrEditDeveloperKey: () => {},
  developerKeysModalClose: () => {},
  editDeveloperKey: () => {},
  listDeveloperKeyScopesSet: () => {},
  resetLtiState: () => {},
  saveLtiToolConfiguration: () => {},
  updateLtiKey: () => {}
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
  redirect_uris: 'http://my_redirect_uri.com',
  user_id: '53532',
  user_name: 'billy bob',
  vendor_code: 'b3w9w9bf',
  workflow_state: 'active',
  test_cluster_only: false
}

const validToolConfig = {
  title: 'testTest',
  description: 'a',
  scopes: [
    'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
    'https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly',
    'https://purl.imsglobal.org/spec/lti-ags/scope/score',
    'https://purl.imsglobal.org/spec/lti-nrps/scope/contextmembership.readonly'
  ],
  extensions: [
    {
      domain: 'test.testcloud.org',
      tool_id: 'toolid',
      platform: 'canvas.instructure.com',
      settings: {
        text: 'test',
        use_1_3: true,
        icon_url: '/img/default-icon-16x16.png',
        selection_width: 500,
        selection_height: 500,
        placements: [
          {
            placement: 'editor_button',
            target_link_uri: 'https://test.testcloud.org/test/lti/store/',
            text: 'testTools',
            enabled: true,
            icon_url: 'https://static.test.org/img/default-icon-16x16.png',
            message_type: 'LtiDeepLinkingRequest',
            canvas_icon_class: 'icon-lti'
          }
        ]
      },
      privacy_level: 'public'
    }
  ],
  target_link_uri: 'https://test.testcloud.org/test/lti/oidc_launch',
  oidc_initiation_url: 'https://test.testcloud.org/test/lti/oidc_login',
  public_jwk: {
    kty: 'RSA',
    e: 'AQAB',
    n: 'vESXFmlzHz-nhZXTkjo29SBpamCzkd7SnpMXgdFEWjLfDeOu0D3JivEEUQ4U67xUBMY9voiJsG2oydMXjgkmGliUIVg-rhyKdBUJu5v6F659FwCj60A8J8qcstIkZfBn3yyOPVwp1FHEUSNvtbDLSRIHFPv-kh8gYyvqz130hE37qAVcaNME7lkbDmH1vbxi3D3A8AxKtiHs8oS41ui2MuSAN9MDb7NjAlFkf2iXlSVxAW5xSek4nHGr4BJKe_13vhLOvRUCTN8h8z-SLORWabxoNIkzuAab0NtfO_Qh0rgoWFC9T69jJPAPsXMDCn5oQ3xh_vhG0vltSSIzHsZ8pw',
    kid: '-1302712033',
    alg: 'RS256',
    use: 'sig'
  }
}

const createLtiKeyState = {
  isLtiKey: false,
  toolConfiguration: {}
}

const createDeveloperKeyState = {
  isLtiKey: false,
  editing: false,
  developerKeyCreateOrEditPending: false,
  developerKeyCreateOrEditSuccessful: false,
  developerKeyCreateOrEditFailed: false,

  developerKeyModalOpen: true,
  developerKey: {id: 22}
}

const editDeveloperKeyState = {
  ...createDeveloperKeyState,
  developerKeyModalOpen: true,
  developerKey
}

const closedDeveloperKeyState = {
  ...createDeveloperKeyState,
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

it('it opens the modal if isOpen prop is true', () => {
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
      ctx={{params: {contextId: '1'}}}
    />
  )
  expect(wrapper.find('Modal').prop('open')).toEqual(true)
})

it('it closes the modal if isOpen prop is false', () => {
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
      ctx={{params: {contextId: '1'}}}
    />
  )
  expect(wrapper.find('Modal').prop('open')).toEqual(false)
})

it('it sends the contents of the form saving', () => {
  const createOrEditSpy = jest.fn()

  const mergedFakeActions = {...fakeActions, createOrEditDeveloperKey: createOrEditSpy}
  const fakeStore = {
    dispatch: () => Promise.resolve()
  }
  const developerKey2 = {
    ...developerKey,
    require_scopes: true,
    scopes: ['test'],
    test_cluster_only: true
  }
  const editDeveloperKeyState2 = {...editDeveloperKeyState, developerKey: developerKey2}

  const wrapper = mount(
    <DeveloperKeyModal
      createLtiKeyState={createLtiKeyState}
      availableScopes={{}}
      availableScopesPending={false}
      closeModal={() => {}}
      createOrEditDeveloperKeyState={editDeveloperKeyState2}
      listDeveloperKeyScopesState={listDeveloperKeyScopesState}
      actions={mergedFakeActions}
      store={fakeStore}
      mountNode={modalMountNode}
      selectedScopes={selectedScopes}
      ctx={{params: {contextId: '1'}}}
    />
  )

  wrapper.instance().submitForm()

  const [[sentFormData]] = createOrEditSpy.mock.calls

  const developer_key = sentFormData.developer_key

  expect(developer_key.name).toEqual(developerKey.name)
  expect(developer_key.email).toEqual(developerKey.email)
  expect(developer_key.redirect_uri).toEqual(developerKey.redirect_uri)
  expect(developer_key.redirect_uris).toEqual(developerKey.redirect_uris)
  expect(developer_key.vendor_code).toEqual(developerKey.vendor_code)
  expect(developer_key.icon_url).toEqual(developerKey.icon_url)
  expect(developer_key.notes).toEqual(developerKey.notes)
  expect(developer_key.require_scopes).toEqual(true)
  expect(developer_key.test_cluster_only).toEqual(true)

  wrapper.unmount()
})

it('sends form content without scopes and require_scopes set to false when not require_scopes', () => {
  const createOrEditSpy = jest.fn()

  const mergedFakeActions = {...fakeActions, createOrEditDeveloperKey: createOrEditSpy}
  const fakeStore = {
    dispatch: () => Promise.resolve()
  }

  const wrapper = mount(
    <DeveloperKeyModal
      createLtiKeyState={createLtiKeyState}
      availableScopes={{}}
      availableScopesPending={false}
      closeModal={() => {}}
      createOrEditDeveloperKeyState={editDeveloperKeyState}
      listDeveloperKeyScopesState={listDeveloperKeyScopesState}
      actions={mergedFakeActions}
      store={fakeStore}
      mountNode={modalMountNode}
      selectedScopes={selectedScopes}
      ctx={{params: {contextId: '1'}}}
    />
  )

  wrapper.instance().submitForm()

  const [[sentFormData]] = createOrEditSpy.mock.calls

  const developer_key = sentFormData.developer_key

  expect(developer_key.name).toEqual(developerKey.name)
  expect(developer_key.email).toEqual(developerKey.email)
  expect(developer_key.redirect_uri).toEqual(developerKey.redirect_uri)
  expect(developer_key.redirect_uris).toEqual(developerKey.redirect_uris)
  expect(developer_key.vendor_code).toEqual(developerKey.vendor_code)
  expect(developer_key.icon_url).toEqual(developerKey.icon_url)
  expect(developer_key.notes).toEqual(developerKey.notes)
  expect(developer_key.require_scopes).toEqual(false)
  expect(developer_key.test_cluster_only).toEqual(false)

  wrapper.unmount()
})

it('it adds each selected scope to the form data', () => {
  const createOrEditSpy = jest.fn()
  const dispatchSpy = () => Promise.resolve()
  const mergedFakeActions = {...fakeActions, createOrEditDeveloperKey: createOrEditSpy}
  const fakeStore = {dispatch: dispatchSpy}
  const developerKey2 = {...developerKey, require_scopes: true, scopes: ['test']}
  const editDeveloperKeyState2 = {...editDeveloperKeyState, developerKey: developerKey2}
  const wrapper = mount(
    <DeveloperKeyModal
      createLtiKeyState={createLtiKeyState}
      availableScopes={{}}
      availableScopesPending={false}
      closeModal={() => {}}
      createOrEditDeveloperKeyState={editDeveloperKeyState2}
      listDeveloperKeyScopesState={listDeveloperKeyScopesState}
      actions={mergedFakeActions}
      store={fakeStore}
      mountNode={modalMountNode}
      selectedScopes={selectedScopes}
      ctx={{params: {contextId: '1'}}}
    />
  )
  wrapper.instance().submitForm()
  const [[sentFormData]] = createOrEditSpy.mock.calls
  const developer_key = sentFormData.developer_key
  expect(developer_key.scopes).toEqual(selectedScopes)

  wrapper.unmount()
})

it('it removes testClusterOnly from the form data if it is undefined', () => {
  const createOrEditSpy = jest.fn()
  const dispatchSpy = () => Promise.resolve()
  const mergedFakeActions = {...fakeActions, createOrEditDeveloperKey: createOrEditSpy}
  const fakeStore = {dispatch: dispatchSpy}
  const developerKey2 = {...developerKey, require_scopes: true, scopes: ['test']}
  delete developerKey2.test_cluster_only
  const editDeveloperKeyState2 = {...editDeveloperKeyState, developerKey: developerKey2}
  const wrapper = mount(
    <DeveloperKeyModal
      createLtiKeyState={createLtiKeyState}
      availableScopes={{}}
      availableScopesPending={false}
      closeModal={() => {}}
      createOrEditDeveloperKeyState={editDeveloperKeyState2}
      listDeveloperKeyScopesState={listDeveloperKeyScopesState}
      actions={mergedFakeActions}
      store={fakeStore}
      mountNode={modalMountNode}
      selectedScopes={selectedScopes}
      ctx={{params: {contextId: '1'}}}
    />
  )
  wrapper.instance().submitForm()
  const [[sentFormData]] = createOrEditSpy.mock.calls
  const developer_key = sentFormData.developer_key
  expect(developer_key.test_cluster_only).toBeFalsy()

  wrapper.unmount()
})

it('flashes an error if no scopes are selected', () => {
  const flashStub = jest.spyOn($, 'flashError')
  const createOrEditSpy = jest.fn()
  const dispatchSpy = () => Promise.resolve()
  const mergedFakeActions = {...fakeActions, createOrEditDeveloperKey: createOrEditSpy}
  const fakeStore = {dispatch: dispatchSpy}
  const developerKey2 = {...developerKey, require_scopes: true, scopes: []}
  const editDeveloperKeyState2 = {...editDeveloperKeyState, developerKey: developerKey2}
  const wrapper = mount(
    <DeveloperKeyModal
      createLtiKeyState={createLtiKeyState}
      availableScopes={{}}
      availableScopesPending={false}
      closeModal={() => {}}
      createOrEditDeveloperKeyState={editDeveloperKeyState2}
      listDeveloperKeyScopesState={listDeveloperKeyScopesState}
      actions={mergedFakeActions}
      store={fakeStore}
      mountNode={modalMountNode}
      selectedScopes={[]}
      ctx={{params: {contextId: '1'}}}
    />
  )
  wrapper.instance().submitForm()
  expect(flashStub).toHaveBeenCalledWith('At least one scope must be selected.')

  wrapper.unmount()
})

it('allows saving if the key previously had scopes', () => {
  const flashStub = jest.spyOn($, 'flashError')
  const dispatchSpy = () => Promise.resolve()
  const fakeStore = {dispatch: dispatchSpy}
  const keyWithScopes = {...developerKey, require_scopes: true, scopes: selectedScopes}
  const editKeyWithScopesState = {...editDeveloperKeyState, developerKey: keyWithScopes}
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
      ctx={{params: {contextId: '1'}}}
    />
  )

  wrapper.instance().submitForm()
  expect(flashStub).not.toHaveBeenCalled()
  wrapper.unmount()
})

it('clears the lti key state when modal is closed', () => {
  const ltiStub = jest.fn()
  const actions = Object.assign(fakeActions, {
    developerKeysModalClose: () => {},
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
      ctx={{params: {contextId: '1'}}}
    />
  )
  wrapper.instance().closeModal()
  expect(ltiStub).toHaveBeenCalled()
  wrapper.unmount()
})

it('flashes an error if redirect_uris is empty', () => {
  const flashStub = jest.spyOn($, 'flashError')
  const createOrEditSpy = jest.fn()
  const dispatchSpy = () => Promise.resolve()
  const mergedFakeActions = {...fakeActions, createOrEditDeveloperKey: createOrEditSpy}
  const fakeStore = {dispatch: dispatchSpy}
  const developerKey2 = {...developerKey, require_scopes: true, scopes: [], redirect_uris: ''}
  const editDeveloperKeyState2 = {...editDeveloperKeyState, developerKey: developerKey2}
  const wrapper = mount(
    <DeveloperKeyModal
      createLtiKeyState={createLtiKeyState}
      availableScopes={{}}
      availableScopesPending={false}
      closeModal={() => {}}
      createOrEditDeveloperKeyState={editDeveloperKeyState2}
      listDeveloperKeyScopesState={listDeveloperKeyScopesState}
      actions={mergedFakeActions}
      store={fakeStore}
      mountNode={modalMountNode}
      selectedScopes={[]}
      ctx={{params: {contextId: '1'}}}
    />
  )
  wrapper.instance().saveLtiToolConfiguration()
  expect(flashStub).toHaveBeenCalledWith('A redirect_uri is required, please supply one.')

  wrapper.unmount()
})

it('renders the saved toolConfiguration if it is present in state', () => {
  const ltiStub = jest.fn()
  const actions = Object.assign(fakeActions, {
    saveLtiToolConfiguration: () => () => ({then: ltiStub})
  })

  const wrapper = mount(
    <DeveloperKeyModal
      createLtiKeyState={{...createLtiKeyState, configurationMethod: 'manual'}}
      availableScopes={{}}
      availableScopesPending={false}
      closeModal={() => {}}
      createOrEditDeveloperKeyState={{
        ...createDeveloperKeyState,
        ...{developerKey: {...developerKey, tool_configuration: validToolConfig}, isLtiKey: true}
      }}
      actions={actions}
      store={{dispatch: () => {}}}
      mountNode={modalMountNode}
      selectedScopes={selectedScopes}
      ctx={{params: {contextId: '1'}}}
    />
  )
  wrapper.instance().saveLtiToolConfiguration()
  expect(wrapper.state().toolConfiguration.oidc_initiation_url).toEqual(
    validToolConfig.oidc_initiation_url
  )
  expect(ltiStub).toHaveBeenCalledTimes(1)
  wrapper.unmount()
})

it('clears state on modal close', () => {
  const ltiStub = jest.fn()
  const actions = Object.assign(fakeActions, {
    updateLtiKey: ltiStub
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
      ctx={{params: {contextId: '1'}}}
    />
  )
  const text = 'I should show up in the text'
  wrapper.instance().setState({toolConfiguration: {oidc_initiation_url: text}})
  wrapper.instance().closeModal()
  expect(wrapper.state('toolConfiguration')).toBeFalsy()
  wrapper.unmount()
})

it('hasRedirectUris', () => {
  developerKey.redirect_uris = null

  const wrapper = mount(
    <DeveloperKeyModal
      createOrEditDeveloperKeyState={{
        ...createDeveloperKeyState,
        ...{developerKey: {...developerKey}, isLtiKey: true}
      }}
      mountNode={modalMountNode}
      // generic required props:
      createLtiKeyState={createLtiKeyState}
      availableScopes={{}}
      availableScopesPending={false}
      closeModal={() => {}}
      actions={fakeActions}
      store={{dispatch: () => {}}}
      selectedScopes={selectedScopes}
      ctx={{params: {contextId: '1'}}}
    />
  )

  expect(wrapper.instance().hasRedirectUris).toEqual(null)

  wrapper.instance().updateToolConfiguration(validToolConfig)

  expect(wrapper.instance().hasRedirectUris).toEqual(true)

  wrapper.unmount()
})

it('update `redirect_uris` when updating the tool configuration', () => {
  const wrapper = mount(
    <DeveloperKeyModal
      createOrEditDeveloperKeyState={{
        ...createDeveloperKeyState,
        ...{developerKey: {...developerKey}, isLtiKey: true}
      }}
      mountNode={modalMountNode}
      // generic required props:
      createLtiKeyState={createLtiKeyState}
      availableScopes={{}}
      availableScopesPending={false}
      closeModal={() => {}}
      actions={fakeActions}
      store={{dispatch: () => {}}}
      selectedScopes={selectedScopes}
      ctx={{params: {contextId: '1'}}}
    />
  )

  wrapper.instance().updateConfigurationMethod('json')
  wrapper.instance().updateToolConfiguration({})

  expect(wrapper.state().developerKey.redirect_uris).toBeFalsy()

  wrapper.instance().updateToolConfiguration(validToolConfig)

  expect(wrapper.state().developerKey.redirect_uris).toEqual(validToolConfig.target_link_uri)

  wrapper.unmount()
})

it('does not flash an error if configurationMethod is url', () => {
  const flashStub = jest.spyOn($, 'flashError')
  const saveLtiToolConfigurationSpy = jest.fn()
  const dispatchSpy = () => Promise.resolve()
  const actions = Object.assign(fakeActions, {
    saveLtiToolConfiguration: () => () => ({then: saveLtiToolConfigurationSpy})
  })
  const wrapper = mount(
    <DeveloperKeyModal
      createLtiKeyState={{}}
      availableScopes={{}}
      availableScopesPending={false}
      createOrEditDeveloperKeyState={editDeveloperKeyState}
      listDeveloperKeyScopesState={listDeveloperKeyScopesState}
      actions={actions}
      store={{dispatch: dispatchSpy}}
      state={{}}
      mountNode={modalMountNode}
      selectedScopes={[]}
      ctx={{params: {contextId: '1'}}}
    />
  )

  wrapper.instance().updateConfigurationMethod('url')
  wrapper.instance().updateToolConfigurationUrl('http://foo.com')
  wrapper.instance().saveLtiToolConfiguration()

  expect(saveLtiToolConfigurationSpy).toHaveBeenCalled()
  expect(flashStub).not.toHaveBeenCalledWith('A redirect_uri is required, please supply one.')

  wrapper.unmount()
})

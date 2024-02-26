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
import devKeyActions from '../actions/developerKeysActions'
import moxios from 'moxios'
import {successfulLtiKeySaveResponse} from './fixtures/responses'
import $ from '@canvas/rails-flash-notifications'

let oldEnv

beforeEach(() => {
  oldEnv = window.ENV
  window.ENV = {
    ...window.ENV,
    validLtiPlacements: [],
    validLtiScopes: {},
  }
})

afterEach(() => {
  window.ENV = oldEnv
  jest.restoreAllMocks()
})

const selectedScopes = [
  'url:POST|/api/v1/accounts/:account_id/account_notifications',
  'url:PUT|/api/v1/accounts/:account_id/account_notifications/:id',
]

const fakeActions = {
  createOrEditDeveloperKey: () => {},
  developerKeysModalClose: () => {},
  editDeveloperKey: () => {},
  listDeveloperKeysReplace: () => {},
  listDeveloperKeyScopesSet: () => {},
  resetLtiState: () => {},
  saveLtiToolConfiguration: () => {},
  updateLtiKey: () => {},
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
  test_cluster_only: false,
}

const validToolConfig = {
  title: 'testTest',
  description: 'a',
  scopes: [
    'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
    'https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly',
    'https://purl.imsglobal.org/spec/lti-ags/scope/score',
    'https://purl.imsglobal.org/spec/lti-nrps/scope/contextmembership.readonly',
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
            canvas_icon_class: 'icon-lti',
          },
        ],
      },
      privacy_level: 'public',
    },
  ],
  target_link_uri: 'https://test.testcloud.org/test/lti/oidc_launch',
  oidc_initiation_url: 'https://test.testcloud.org/test/lti/oidc_login',
  public_jwk: {
    kty: 'RSA',
    e: 'AQAB',
    n: 'vESXFmlzHz-nhZXTkjo29SBpamCzkd7SnpMXgdFEWjLfDeOu0D3JivEEUQ4U67xUBMY9voiJsG2oydMXjgkmGliUIVg-rhyKdBUJu5v6F659FwCj60A8J8qcstIkZfBn3yyOPVwp1FHEUSNvtbDLSRIHFPv-kh8gYyvqz130hE37qAVcaNME7lkbDmH1vbxi3D3A8AxKtiHs8oS41ui2MuSAN9MDb7NjAlFkf2iXlSVxAW5xSek4nHGr4BJKe_13vhLOvRUCTN8h8z-SLORWabxoNIkzuAab0NtfO_Qh0rgoWFC9T69jJPAPsXMDCn5oQ3xh_vhG0vltSSIzHsZ8pw',
    kid: '-1302712033',
    alg: 'RS256',
    use: 'sig',
  },
}

const createLtiKeyState = {
  isLtiKey: false,
  toolConfiguration: {},
}

const createDeveloperKeyState = {
  isLtiKey: false,
  editing: false,
  developerKeyCreateOrEditPending: false,
  developerKeyCreateOrEditSuccessful: false,
  developerKeyCreateOrEditFailed: false,

  developerKeyModalOpen: true,
  developerKey: {id: 22},
}

const editDeveloperKeyState = {
  ...createDeveloperKeyState,
  developerKeyModalOpen: true,
  developerKey,
}

const closedDeveloperKeyState = {
  ...createDeveloperKeyState,
  developerKeyModalOpen: false,
  developerKey,
}

const listDeveloperKeyScopesState = {
  availableScopes: {},
  listDeveloperKeyScopesPending: true,
}

function modalMountNode() {
  return document.querySelector('#fixtures')
}

const modal = extraProps => (
  <DeveloperKeyModal
    availableScopes={{}}
    availableScopesPending={false}
    closeModal={() => {}}
    ctx={{params: {contextId: '1'}}}
    mountNode={modalMountNode}
    selectedScopes={selectedScopes}
    store={{dispatch: () => Promise.resolve()}}
    handleSuccessfulSave={() => {}}
    {...extraProps}
  />
)

describe('isOpen prop', () => {
  function modalWithState(createOrEditDeveloperKeyState) {
    return shallow(
      modal({
        createLtiKeyState,
        createOrEditDeveloperKeyState,
        actions: fakeActions,
      })
    )
  }

  it('opens the modal if isOpen prop is true', () => {
    const wrapper = modalWithState(createDeveloperKeyState)
    expect(wrapper.find('Modal').prop('open')).toEqual(true)
  })

  it('closes the modal if isOpen prop is false', () => {
    const wrapper = modalWithState(closedDeveloperKeyState)
    expect(wrapper.find('Modal').prop('open')).toEqual(false)
  })
})

describe('submitting the form', () => {
  function submitForm(createOrEditDeveloperKeyState) {
    const mergedFakeActions = {...fakeActions, createOrEditDeveloperKey: jest.fn()}
    const wrapper = mount(
      modal({
        actions: mergedFakeActions,
        createLtiKeyState,
        createOrEditDeveloperKeyState,
        listDeveloperKeyScopesState,
      })
    )

    wrapper.instance().submitForm()
    const [[sentFormData]] = mergedFakeActions.createOrEditDeveloperKey.mock.calls
    const sentDevKey = sentFormData.developer_key
    wrapper.unmount()

    return sentDevKey
  }

  it('sends the contents of the form saving', () => {
    const developerKey2 = {
      ...developerKey,
      require_scopes: true,
      scopes: ['test'],
      test_cluster_only: true,
    }
    const editDeveloperKeyState2 = {...editDeveloperKeyState, developerKey: developerKey2}

    const sentDevKey = submitForm(editDeveloperKeyState2)
    expect(sentDevKey).toEqual({
      ...developerKey,
      scopes: selectedScopes,
      require_scopes: true,
      test_cluster_only: true,
    })
  })

  it('sends form content without scopes and require_scopes set to false when not require_scopes', () => {
    const sentDevKey = submitForm(editDeveloperKeyState)
    expect(sentDevKey).toEqual({
      ...developerKey,
      require_scopes: false,
      test_cluster_only: false,
    })
  })

  it('adds each selected scope to the form data', () => {
    const developerKey2 = {...developerKey, require_scopes: true, scopes: ['test']}
    const editDeveloperKeyState2 = {...editDeveloperKeyState, developerKey: developerKey2}
    const sentDevKey = submitForm(editDeveloperKeyState2)
    expect(sentDevKey.scopes).toEqual(selectedScopes)
  })

  it('removes testClusterOnly from the form data if it is undefined', () => {
    const developerKey2 = {...developerKey, require_scopes: true, scopes: ['test']}
    delete developerKey2.test_cluster_only
    const editDeveloperKeyState2 = {...editDeveloperKeyState, developerKey: developerKey2}
    const sentDevKey = submitForm(editDeveloperKeyState2)
    expect(sentDevKey.test_cluster_only).toBeFalsy()
  })
})

describe('scope selection', () => {
  it('flashes an error if no scopes are selected', () => {
    const flashStub = jest.spyOn($, 'flashError')
    const createOrEditSpy = jest.fn()
    const mergedFakeActions = {...fakeActions, createOrEditDeveloperKey: createOrEditSpy}
    const developerKey2 = {...developerKey, require_scopes: true, scopes: []}
    const editDeveloperKeyState2 = {...editDeveloperKeyState, developerKey: developerKey2}
    const wrapper = mount(
      modal({
        createLtiKeyState,
        createOrEditDeveloperKeyState: editDeveloperKeyState2,
        listDeveloperKeyScopesState,
        selectedScopes: [],
        actions: mergedFakeActions,
      })
    )
    wrapper.instance().submitForm()
    expect(flashStub).toHaveBeenCalledWith('At least one scope must be selected.')

    wrapper.unmount()
  })

  it('allows saving if the key previously had scopes', () => {
    const flashStub = jest.spyOn($, 'flashError')
    const keyWithScopes = {...developerKey, require_scopes: true, scopes: selectedScopes}
    const editKeyWithScopesState = {...editDeveloperKeyState, developerKey: keyWithScopes}
    const wrapper = mount(
      modal({
        createLtiKeyState,
        createOrEditDeveloperKeyState: editKeyWithScopesState,
        listDeveloperKeyScopesState,
        actions: fakeActions,
      })
    )

    wrapper.instance().submitForm()
    expect(flashStub).not.toHaveBeenCalled()
    wrapper.unmount()
  })
})

describe('a11y checks', () => {
  it('renders the saving spinner with a polite aria-live attribute', () => {
    const wrapper = shallow(
      modal({
        createOrEditDeveloperKeyState: {
          ...createDeveloperKeyState,
        },
        actions: {
          ...fakeActions,
        },
      })
    )

    wrapper.setState({isSaving: true})

    expect(wrapper.find('Spinner').first().getElement().props['aria-live']).toBe('polite')
  })

  describe('flash alerts checks', () => {
    const successfulSaveStub = jest.fn()

    function createWrapper(stateOverrides, actionOverrides) {
      return mount(
        modal({
          createOrEditDeveloperKeyState: {
            ...createDeveloperKeyState,
            developerKey: {
              ...developerKey,
              tool_configuration: {
                ...validToolConfig,
              },
            },
            ...stateOverrides,
          },
          actions: {
            ...fakeActions,
            ...actionOverrides,
          },
          handleSuccessfulSave: successfulSaveStub,
        })
      )
    }

    afterEach(() => {
      successfulSaveStub.mockClear()
    })
    describe('LTI Developer Key is being created', () => {
      it('notifies if the key saves successfully', async () => {
        const saveLtiToolConfigurationStub = jest.fn().mockImplementation(() => {
          return () => {
            return Promise.resolve({
              developer_key: developerKey,
              tool_configuration: validToolConfig,
            })
          }
        })

        const wrapper = createWrapper(
          {isLtiKey: true},
          {saveLtiToolConfiguration: saveLtiToolConfigurationStub}
        )

        await wrapper.instance().saveLtiToolConfiguration()

        expect(saveLtiToolConfigurationStub).toHaveBeenCalled()
        expect(successfulSaveStub).toHaveBeenCalledTimes(1)
        wrapper.unmount()
      })

      it("doesn't notify if the key fails to be created", async () => {
        const saveLtiToolConfigurationStub = jest.fn().mockImplementation(() => {
          return () => {
            return Promise.reject(new Error('testing'))
          }
        })

        const wrapper = createWrapper(
          {isLtiKey: true},
          {saveLtiToolConfiguration: saveLtiToolConfigurationStub}
        )

        await wrapper.instance().saveLtiToolConfiguration()

        expect(saveLtiToolConfigurationStub).toHaveBeenCalled()
        expect(successfulSaveStub).not.toHaveBeenCalled()
        wrapper.unmount()
      })

      it('notifies and forwards if the API returns a warning_message', async () => {
        const warning_message = 'This is a warning message'
        const saveLtiToolConfigurationStub = jest.fn().mockImplementation(() => {
          return () => {
            return Promise.resolve({
              developer_key: developerKey,
              tool_configuration: validToolConfig,
              warning_message,
            })
          }
        })

        const wrapper = createWrapper(
          {isLtiKey: true},
          {saveLtiToolConfiguration: saveLtiToolConfigurationStub}
        )

        await wrapper.instance().saveLtiToolConfiguration()

        expect(saveLtiToolConfigurationStub).toHaveBeenCalled()
        expect(successfulSaveStub).toHaveBeenCalledWith(warning_message)
      })
    })

    describe('LTI Developer Key is being edited', () => {
      it('notifies if the key saves successfully', async () => {
        const updateLtiKeyStub = jest.fn().mockResolvedValue({
          developer_key: developerKey,
          tool_configuration: validToolConfig,
        })

        const wrapper = createWrapper({}, {updateLtiKey: updateLtiKeyStub})

        await wrapper
          .instance()
          .saveLTIKeyEdit(validToolConfig.extensions[0].settings, developerKey)

        expect(updateLtiKeyStub).toHaveBeenCalled()
        expect(successfulSaveStub).toHaveBeenCalledTimes(1)
        wrapper.unmount()
      })

      it("doesn't notifiy if the key fails to save", async () => {
        const updateLtiKeyStub = jest.fn().mockRejectedValue(null)
        const wrapper = createWrapper({}, {updateLtiKey: updateLtiKeyStub})

        await wrapper
          .instance()
          .saveLTIKeyEdit(validToolConfig.extensions[0].settings, developerKey)

        expect(updateLtiKeyStub).toHaveBeenCalled()
        expect(successfulSaveStub).not.toHaveBeenCalled()
        wrapper.unmount()
      })

      it('notifies if the API returns a warning_message', async () => {
        const warning_message = 'This is a warning message'
        const updateLtiKeyStub = jest.fn().mockResolvedValue({
          developer_key: developerKey,
          tool_configuration: validToolConfig,
          warning_message,
        })

        const wrapper = createWrapper({isLtiKey: true}, {updateLtiKey: updateLtiKeyStub})

        await wrapper
          .instance()
          .saveLTIKeyEdit(validToolConfig.extensions[0].settings, developerKey)

        expect(updateLtiKeyStub).toHaveBeenCalled()
        expect(successfulSaveStub).toHaveBeenCalledWith(warning_message)
      })
    })

    // Turns out, for API keys, there's no difference in the code path taken,
    // at least with respect to flashing an alert
    describe('API Dev Key is being created/edited', () => {
      it('flashes an alert if the key saves successfully', async () => {
        const createOrEditStub = jest.fn().mockImplementation(() => {
          return () => {
            return Promise.resolve(null)
          }
        })

        // TODO: Modify this state so that it shows a key being created, not being edited.
        const wrapper = createWrapper(
          {
            developerKeyCreateOrEditSuccessful: true,
            developerKeyCreateOrEditPending: false,
            developerKeyCreateOrEditFailed: false,
          },
          {createOrEditDeveloperKey: createOrEditStub}
        )

        await wrapper.instance().submitForm()

        expect(createOrEditStub).toHaveBeenCalled()
        expect(successfulSaveStub).toHaveBeenCalledTimes(1)
        wrapper.unmount()
      })

      it("doesn't flash an alert if the key fails to save", async () => {
        const createOrEditStub = jest.fn().mockImplementation(() => {
          return () => {
            return Promise.resolve(null)
          }
        })

        // TODO: Modify this state so that it shows a key being created, not being edited.
        const wrapper = createWrapper(
          {
            developerKeyCreateOrEditSuccessful: false,
            developerKeyCreateOrEditPending: false,
            developerKeyCreateOrEditFailed: true,
          },
          {createOrEditDeveloperKey: createOrEditStub}
        )

        await wrapper.instance().submitForm()

        expect(createOrEditStub).toHaveBeenCalled()
        expect(successfulSaveStub).not.toHaveBeenCalledTimes(1)
        wrapper.unmount()
      })
    })
  })
})

it('clears the lti key state when modal is closed', () => {
  const ltiStub = jest.fn()
  const actions = Object.assign(fakeActions, {
    developerKeysModalClose: () => {},
    resetLtiState: ltiStub,
  })

  const wrapper = mount(
    modal({
      createLtiKeyState,
      createOrEditDeveloperKeyState: createDeveloperKeyState,
      actions,
    })
  )
  wrapper.instance().closeModal()
  expect(ltiStub).toHaveBeenCalled()
  wrapper.unmount()
})

it('flashes an error if redirect_uris is empty', () => {
  const flashStub = jest.spyOn($, 'flashError')
  const createOrEditSpy = jest.fn()
  const mergedFakeActions = {...fakeActions, createOrEditDeveloperKey: createOrEditSpy}
  const developerKey2 = {...developerKey, require_scopes: true, scopes: [], redirect_uris: ''}
  const editDeveloperKeyState2 = {...editDeveloperKeyState, developerKey: developerKey2}
  const wrapper = mount(
    modal({
      createLtiKeyState,
      createOrEditDeveloperKeyState: editDeveloperKeyState2,
      listDeveloperKeyScopesState,
      actions: mergedFakeActions,
      selectedScopes: [],
    })
  )
  wrapper.instance().saveLtiToolConfiguration()
  expect(flashStub).toHaveBeenCalledWith('A redirect_uri is required, please supply one.')

  wrapper.unmount()
})

describe('redirect_uris is too long', () => {
  let flashStub
  const createOrEditSpy = jest.fn()
  const actions = {...fakeActions, createOrEditDeveloperKey: createOrEditSpy}
  const devKey = {
    ...developerKey,
    require_scopes: true,
    redirect_uris: 'https://example.com/' + 'a'.repeat(4096),
  }
  const state = {...editDeveloperKeyState, developerKey: devKey}
  const expectedMsg =
    "One of the supplied redirect_uris is too long. Please ensure you've entered the correct value(s) for your redirect_uris."
  let wrapper

  beforeEach(() => {
    flashStub = jest.spyOn($, 'flashError')
    wrapper = mount(
      modal({
        createLtiKeyState,
        createOrEditDeveloperKeyState: state,
        listDeveloperKeyScopesState,
        actions,
        selectedScopes,
      })
    )
  })

  afterEach(() => {
    flashStub.mockClear()
    wrapper.unmount()
  })

  describe('and the key being saved is an LTI key', () => {
    it('tries to flash an error saying the given redirect_uri is too long', () => {
      wrapper.instance().saveLtiToolConfiguration()
      expect(wrapper.instance().hasInvalidRedirectUris).toBeTruthy()
      expect(flashStub).toHaveBeenCalledWith(expectedMsg)
    })
  })

  describe('and the key being saved is an API key', () => {
    it('tries to flash an error saying the given redirect_uri is too long', () => {
      wrapper.instance().submitForm()
      expect(wrapper.instance().hasInvalidRedirectUris).toBeTruthy()
      expect(flashStub).toHaveBeenCalledWith(expectedMsg)
    })
  })
})

describe('receiving an HTTP response', () => {
  beforeEach(() => {
    moxios.install()
  })

  const createModalAndSaveKey = modalProps => {
    const wrapper = mount(modal(modalProps))
    wrapper.instance().setState({configurationMethod: 'json'})
    wrapper.instance().saveLtiToolConfiguration()

    wrapper.unmount()
  }

  it('shows flash message and closes modal', done => {
    const handleSuccessfulSave = jest.fn()
    const closeModal = jest.fn()

    moxios.wait(async () => {
      const request = moxios.requests.mostRecent()
      await request.respondWith(successfulLtiKeySaveResponse)
      // The actual flash alert call happens in App.js after handleSuccessfulSave
      // is called, so making sure that handleSuccessfulSave is called is the best
      // we can test for in this component. That is different from errors, where
      // we call $.flashError in this component.
      expect(handleSuccessfulSave).toHaveBeenCalled()
      expect(closeModal).toHaveBeenCalled()
      done()
    })

    const modalProps = {
      createLtiKeyState,
      createOrEditDeveloperKeyState: {...editDeveloperKeyState, editing: true},
      listDeveloperKeyScopesState,
      actions: {...devKeyActions, developerKeysModalClose: closeModal},
      handleSuccessfulSave,
    }
    createModalAndSaveKey(modalProps)
  })

  it('shows flash message and leaves modal open', done => {
    const flashStub = jest.spyOn($, 'flashError')
    const closeModal = jest.fn()

    moxios.wait(async () => {
      const request = moxios.requests.mostRecent()
      await request.respondWith({
        status: 422,
        response: {
          errors: [
            {
              field: 'lti_key',
              message: 'Tool configuration must have public jwk or public jwk url',
              error_code: null,
            },
          ],
        },
      })
      expect(flashStub).toHaveBeenCalledWith(
        'Tool configuration must have public jwk or public jwk url'
      )
      expect(closeModal).not.toHaveBeenCalled()
      done()
    })

    const modalProps = {
      createLtiKeyState,
      createOrEditDeveloperKeyState: {...editDeveloperKeyState, editing: true},
      listDeveloperKeyScopesState,
      actions: {...devKeyActions, developerKeysModalClose: closeModal},
    }
    createModalAndSaveKey(modalProps)
  })
})

it('renders the saved toolConfiguration if it is present in state', () => {
  const ltiStub = jest.fn()
  const actions = Object.assign(fakeActions, {
    saveLtiToolConfiguration: () => () => ({then: ltiStub}),
  })

  const wrapper = mount(
    modal({
      createLtiKeyState: {...createLtiKeyState, configurationMethod: 'manual'},
      createOrEditDeveloperKeyState: {
        ...createDeveloperKeyState,
        ...{developerKey: {...developerKey, tool_configuration: validToolConfig}, isLtiKey: true},
      },
      actions,
    })
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
    updateLtiKey: ltiStub,
  })

  const wrapper = mount(
    modal({
      createLtiKeyState,
      createOrEditDeveloperKeyState: createDeveloperKeyState,
      actions,
    })
  )
  const text = 'I should show up in the text'
  wrapper.instance().setState({toolConfiguration: {oidc_initiation_url: text}})
  wrapper.instance().closeModal()
  expect(wrapper.state('toolConfiguration')).toBeFalsy()
  wrapper.unmount()
})

it('hasRedirectUris', () => {
  developerKey.redirect_uris = ''

  const wrapper = mount(
    modal({
      createOrEditDeveloperKeyState: {
        ...createDeveloperKeyState,
        ...{developerKey: {...developerKey}, isLtiKey: true},
      },
      // generic required props:
      createLtiKeyState,
      actions: fakeActions,
    })
  )

  expect(wrapper.instance().hasRedirectUris).toEqual(false)

  wrapper.instance().updateToolConfiguration(validToolConfig)

  expect(wrapper.instance().hasRedirectUris).toEqual(true)

  wrapper.unmount()
})

describe('redirect_uris automatic setting', () => {
  let wrapper

  beforeEach(() => {
    wrapper = mount(
      modal({
        createOrEditDeveloperKeyState: {
          ...createDeveloperKeyState,
          ...{developerKey: {...developerKey}, isLtiKey: true},
        },
        // generic required props:
        createLtiKeyState,
        actions: fakeActions,
      })
    )

    wrapper.instance().updateConfigurationMethod('json')
    wrapper.instance().updateToolConfiguration({})
  })

  afterEach(() => wrapper.unmount())

  it('updates `redirect_uris` when updating the tool configuration', () => {
    expect(wrapper.state().developerKey.redirect_uris).toBeFalsy()
    wrapper.instance().updateToolConfiguration(validToolConfig)
    expect(wrapper.state().developerKey.redirect_uris).toEqual(validToolConfig.target_link_uri)
  })

  it('does not update `redirect_uris` if already set when updating the tool configuration', () => {
    wrapper.setState({
      developerKey: {
        ...developerKey,
        redirect_uris: 'http://my_redirect_uri.com\nhttp://google.com\nhttp://msn.com',
      },
    })
    wrapper.instance().updateToolConfiguration(validToolConfig)
    expect(wrapper.instance().developerKey.redirect_uris).toEqual(
      'http://my_redirect_uri.com\nhttp://google.com\nhttp://msn.com'
    )
  })

  it('does update `redirect_uris` if already set when using the `Sync URIs` button', () => {
    wrapper.instance().updateToolConfiguration(validToolConfig)
    wrapper.setState({
      developerKey: {
        ...developerKey,
        redirect_uris: 'http://my_redirect_uri.com\nhttp://google.com\nhttp://msn.com',
        tool_configuration: validToolConfig,
      },
    })
    wrapper.instance().syncRedirectUris()
    expect(wrapper.instance().developerKey.redirect_uris).toEqual(validToolConfig.target_link_uri)
  })
})

it('does not flash an error if configurationMethod is url', () => {
  const flashStub = jest.spyOn($, 'flashError')
  const saveLtiToolConfigurationSpy = jest.fn()
  const actions = Object.assign(fakeActions, {
    saveLtiToolConfiguration: () => () => ({then: saveLtiToolConfigurationSpy}),
  })
  const wrapper = mount(
    modal({
      createLtiKeyState: {},
      createOrEditDeveloperKeyState: editDeveloperKeyState,
      listDeveloperKeyScopesState,
      actions,
      selectedScopes: [],
      state: {},
    })
  )

  wrapper.instance().updateConfigurationMethod('url')
  wrapper.instance().updateToolConfigurationUrl('http://foo.com')
  wrapper.instance().saveLtiToolConfiguration()

  expect(saveLtiToolConfigurationSpy).toHaveBeenCalled()
  expect(flashStub).not.toHaveBeenCalledWith('A redirect_uri is required, please supply one.')

  wrapper.unmount()
})

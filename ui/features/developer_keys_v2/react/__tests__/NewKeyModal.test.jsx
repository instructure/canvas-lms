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
import {render, cleanup} from '@testing-library/react'
import DeveloperKeyModal from '../NewKeyModal'
import devKeyActions from '../actions/developerKeysActions'
import moxios from 'moxios'
import {successfulLtiKeySaveResponse} from './fixtures/responses'
import $ from '@canvas/rails-flash-notifications'

describe('NewKeyModal', () => {
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

  const mountNode = () => document.querySelector('#fixtures')

  const defaultProps = (props = {}) => ({
    selectedScopes,
    availableScopes: {},
    availableScopesPending: false,
    closeModal: () => {},
    ctx: {params: {contextId: '1'}},
    mountNode,
    store: {dispatch: () => Promise.resolve()},
    handleSuccessfulSave: () => {},
    ...props,
  })

  const renderDeveloperKeyModal = props => {
    const ref = React.createRef()

    return {
      ref,
      wrapper: render(<DeveloperKeyModal {...defaultProps(props)} ref={ref} />),
    }
  }

  describe('isOpen prop', () => {
    const modalWithState = createOrEditDeveloperKeyState =>
      renderDeveloperKeyModal({
        createLtiKeyState,
        createOrEditDeveloperKeyState,
        actions: fakeActions,
      })

    it('opens the modal if isOpen prop is true', () => {
      const {wrapper} = modalWithState(createDeveloperKeyState)
      const modal = wrapper.getByRole('dialog')

      expect(modal).toBeInTheDocument()
    })

    it('closes the modal if isOpen prop is false', () => {
      modalWithState(closedDeveloperKeyState)

      const modal = document.querySelector('[role="dialog"]')

      expect(modal).not.toBeInTheDocument()
    })
  })

  describe('submitting the form', () => {
    function submitForm(createOrEditDeveloperKeyState) {
      const mergedFakeActions = {...fakeActions, createOrEditDeveloperKey: jest.fn()}
      const {ref} = renderDeveloperKeyModal({
        actions: mergedFakeActions,
        createLtiKeyState,
        createOrEditDeveloperKeyState,
        listDeveloperKeyScopesState,
      })

      ref.current.submitForm()

      const [[sentFormData]] = mergedFakeActions.createOrEditDeveloperKey.mock.calls
      const sentDevKey = sentFormData.developer_key

      cleanup()

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
    afterEach(() => {
      cleanup()
    })

    it('flashes an error if no scopes are selected', () => {
      const flashStub = jest.spyOn($, 'flashError')
      const createOrEditSpy = jest.fn()
      const mergedFakeActions = {...fakeActions, createOrEditDeveloperKey: createOrEditSpy}
      const developerKey2 = {...developerKey, require_scopes: true, scopes: []}
      const editDeveloperKeyState2 = {...editDeveloperKeyState, developerKey: developerKey2}
      const {ref} = renderDeveloperKeyModal({
        createLtiKeyState,
        createOrEditDeveloperKeyState: editDeveloperKeyState2,
        listDeveloperKeyScopesState,
        selectedScopes: [],
        actions: mergedFakeActions,
      })

      ref.current.submitForm()

      expect(flashStub).toHaveBeenCalledWith('At least one scope must be selected.')
    })

    it('allows saving if the key previously had scopes', () => {
      const flashStub = jest.spyOn($, 'flashError')
      const keyWithScopes = {...developerKey, require_scopes: true, scopes: selectedScopes}
      const editKeyWithScopesState = {...editDeveloperKeyState, developerKey: keyWithScopes}
      const {ref} = renderDeveloperKeyModal({
        createLtiKeyState,
        createOrEditDeveloperKeyState: editKeyWithScopesState,
        listDeveloperKeyScopesState,
        actions: fakeActions,
      })

      ref.current.submitForm()

      expect(flashStub).not.toHaveBeenCalled()
    })
  })

  describe('a11y checks', () => {
    it('renders the saving spinner with a polite aria-live attribute', () => {
      const {wrapper, ref} = renderDeveloperKeyModal({
        createOrEditDeveloperKeyState: {
          ...createDeveloperKeyState,
        },
        actions: {
          ...fakeActions,
        },
      })

      ref.current.setState({isSaving: true})

      expect(
        wrapper.getByRole('img', {
          name: /creating key/i,
        })
      ).toBeInTheDocument()
      expect(document.querySelector('div[aria-live="polite"]')).toBeInTheDocument()
    })

    describe('flash alerts checks', () => {
      const successfulSaveStub = jest.fn()

      const createWrapper = (stateOverrides, actionOverrides) =>
        renderDeveloperKeyModal({
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
          const {ref} = createWrapper(
            {isLtiKey: true},
            {saveLtiToolConfiguration: saveLtiToolConfigurationStub}
          )

          await ref.current.saveLtiToolConfiguration()

          expect(saveLtiToolConfigurationStub).toHaveBeenCalled()
          expect(successfulSaveStub).toHaveBeenCalledTimes(1)
        })

        it("doesn't notify if the key fails to be created", async () => {
          const saveLtiToolConfigurationStub = jest
            .fn()
            .mockImplementation(() => () => Promise.reject(new Error('testing')))
          const {ref} = createWrapper(
            {isLtiKey: true},
            {saveLtiToolConfiguration: saveLtiToolConfigurationStub}
          )

          await ref.current.saveLtiToolConfiguration()

          expect(saveLtiToolConfigurationStub).toHaveBeenCalled()
          expect(successfulSaveStub).not.toHaveBeenCalled()
        })

        it('notifies and forwards if the API returns a warning_message', async () => {
          const warning_message = 'This is a warning message'
          const saveLtiToolConfigurationStub = jest.fn().mockImplementation(
            () => () =>
              Promise.resolve({
                developer_key: developerKey,
                tool_configuration: validToolConfig,
                warning_message,
              })
          )
          const {ref} = createWrapper(
            {isLtiKey: true},
            {saveLtiToolConfiguration: saveLtiToolConfigurationStub}
          )

          await ref.current.saveLtiToolConfiguration()

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

          const {ref} = createWrapper({}, {updateLtiKey: updateLtiKeyStub})

          await ref.current.saveLTIKeyEdit(validToolConfig.extensions[0].settings, developerKey)

          expect(updateLtiKeyStub).toHaveBeenCalled()
          expect(successfulSaveStub).toHaveBeenCalledTimes(1)
        })

        it("doesn't notifiy if the key fails to save", async () => {
          const updateLtiKeyStub = jest.fn().mockRejectedValue(null)
          const {ref} = createWrapper({}, {updateLtiKey: updateLtiKeyStub})

          await ref.current.saveLTIKeyEdit(validToolConfig.extensions[0].settings, developerKey)

          expect(updateLtiKeyStub).toHaveBeenCalled()
          expect(successfulSaveStub).not.toHaveBeenCalled()
        })

        it('notifies if the API returns a warning_message', async () => {
          const warning_message = 'This is a warning message'
          const updateLtiKeyStub = jest.fn().mockResolvedValue({
            developer_key: developerKey,
            tool_configuration: validToolConfig,
            warning_message,
          })

          const {ref} = createWrapper({isLtiKey: true}, {updateLtiKey: updateLtiKeyStub})

          await ref.current.saveLTIKeyEdit(validToolConfig.extensions[0].settings, developerKey)

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
          const {ref} = createWrapper(
            {
              developerKeyCreateOrEditSuccessful: true,
              developerKeyCreateOrEditPending: false,
              developerKeyCreateOrEditFailed: false,
            },
            {createOrEditDeveloperKey: createOrEditStub}
          )

          await ref.current.submitForm()

          expect(createOrEditStub).toHaveBeenCalled()
          expect(successfulSaveStub).toHaveBeenCalledTimes(1)
        })

        it("doesn't flash an alert if the key fails to save", async () => {
          const createOrEditStub = jest.fn().mockImplementation(() => {
            return () => {
              return Promise.resolve(null)
            }
          })

          // TODO: Modify this state so that it shows a key being created, not being edited.
          const {ref} = createWrapper(
            {
              developerKeyCreateOrEditSuccessful: false,
              developerKeyCreateOrEditPending: false,
              developerKeyCreateOrEditFailed: true,
            },
            {createOrEditDeveloperKey: createOrEditStub}
          )

          await ref.current.submitForm()

          expect(createOrEditStub).toHaveBeenCalled()
          expect(successfulSaveStub).not.toHaveBeenCalledTimes(1)
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
    const {ref} = renderDeveloperKeyModal({
      createLtiKeyState,
      createOrEditDeveloperKeyState: createDeveloperKeyState,
      actions,
    })

    ref.current.closeModal()

    expect(ltiStub).toHaveBeenCalled()
  })

  it('flashes an error if redirect_uris is empty', () => {
    const flashStub = jest.spyOn($, 'flashError')
    const createOrEditSpy = jest.fn()
    const mergedFakeActions = {...fakeActions, createOrEditDeveloperKey: createOrEditSpy}
    const developerKey2 = {...developerKey, require_scopes: true, scopes: [], redirect_uris: ''}
    const editDeveloperKeyState2 = {...editDeveloperKeyState, developerKey: developerKey2}
    const {ref} = renderDeveloperKeyModal({
      createLtiKeyState,
      createOrEditDeveloperKeyState: editDeveloperKeyState2,
      listDeveloperKeyScopesState,
      actions: mergedFakeActions,
      selectedScopes: [],
    })

    ref.current.saveLtiToolConfiguration()

    expect(flashStub).toHaveBeenCalledWith('A redirect_uri is required, please supply one.')
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
    let ref

    beforeEach(() => {
      flashStub = jest.spyOn($, 'flashError')
      const {ref: reference} = renderDeveloperKeyModal({
        createLtiKeyState,
        createOrEditDeveloperKeyState: state,
        listDeveloperKeyScopesState,
        actions,
        selectedScopes,
      })

      ref = reference
    })

    afterEach(() => {
      flashStub.mockClear()
    })

    describe('and the key being saved is an LTI key', () => {
      it('tries to flash an error saying the given redirect_uri is too long', () => {
        ref.current.saveLtiToolConfiguration()

        expect(ref.current.hasInvalidRedirectUris).toBeTruthy()
        expect(flashStub).toHaveBeenCalledWith(expectedMsg)
      })
    })

    describe('and the key being saved is an API key', () => {
      it('tries to flash an error saying the given redirect_uri is too long', () => {
        ref.current.submitForm()
        expect(ref.current.hasInvalidRedirectUris).toBeTruthy()
        expect(flashStub).toHaveBeenCalledWith(expectedMsg)
      })
    })
  })

  describe('receiving an HTTP response', () => {
    beforeEach(() => {
      moxios.install()
    })

    const createModalAndSaveKey = modalProps => {
      const {ref} = renderDeveloperKeyModal(modalProps)

      ref.current.setState({configurationMethod: 'json', toolConfiguration: {key: 'value'}})
      ref.current.saveLtiToolConfiguration()
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
        createOrEditDeveloperKeyState: {...editDeveloperKeyState, editing: true, isLtiKey: true},
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
        createOrEditDeveloperKeyState: {...editDeveloperKeyState, editing: true, isLtiKey: true},
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

    const {ref} = renderDeveloperKeyModal({
      createLtiKeyState: {...createLtiKeyState, configurationMethod: 'manual'},
      createOrEditDeveloperKeyState: {
        ...createDeveloperKeyState,
        ...{developerKey: {...developerKey, tool_configuration: validToolConfig}, isLtiKey: true},
      },
      actions,
    })

    ref.current.saveLtiToolConfiguration()

    expect(ref.current.state.toolConfiguration.oidc_initiation_url).toEqual(
      validToolConfig.oidc_initiation_url
    )
    expect(ltiStub).toHaveBeenCalledTimes(1)
  })

  it('clears state on modal close', () => {
    const ltiStub = jest.fn()
    const actions = {
      ...fakeActions,
      updateLtiKey: ltiStub,
    }
    const {ref} = renderDeveloperKeyModal({
      createLtiKeyState,
      createOrEditDeveloperKeyState: createDeveloperKeyState,
      actions,
    })
    const text = 'I should show up in the text'

    ref.current.setState({toolConfiguration: {oidc_initiation_url: text}})
    ref.current.closeModal()

    expect(ref.current.state.toolConfiguration).toBeFalsy()
  })

  it('hasRedirectUris', () => {
    developerKey.redirect_uris = ''

    const {ref} = renderDeveloperKeyModal({
      createOrEditDeveloperKeyState: {
        ...createDeveloperKeyState,
        ...{developerKey: {...developerKey}, isLtiKey: true},
      },
      createLtiKeyState,
      actions: fakeActions,
    })

    expect(ref.current.hasRedirectUris).toEqual(false)

    ref.current.updateToolConfiguration(validToolConfig)

    expect(ref.current.hasRedirectUris).toEqual(true)
  })

  describe('redirect_uris automatic setting', () => {
    let ref

    beforeEach(() => {
      const {ref: reference} = renderDeveloperKeyModal({
        createOrEditDeveloperKeyState: {
          ...createDeveloperKeyState,
          ...{developerKey: {...developerKey}, isLtiKey: true},
        },
        createLtiKeyState,
        actions: fakeActions,
      })

      ref = reference

      ref.current.updateConfigurationMethod('json')
      ref.current.updateToolConfiguration({})
    })

    it('updates `redirect_uris` when updating the tool configuration', () => {
      expect(ref.current.developerKey.redirect_uris).toBeFalsy()

      ref.current.updateToolConfiguration(validToolConfig)

      expect(ref.current.developerKey.redirect_uris).toEqual(validToolConfig.target_link_uri)
    })

    it('does not update `redirect_uris` if already set when updating the tool configuration', () => {
      ref.current.setState({
        developerKey: {
          ...developerKey,
          redirect_uris: 'http://my_redirect_uri.com\nhttp://google.com\nhttp://msn.com',
        },
      })
      ref.current.updateToolConfiguration(validToolConfig)
      expect(ref.current.developerKey.redirect_uris).toEqual(
        'http://my_redirect_uri.com\nhttp://google.com\nhttp://msn.com'
      )
    })

    it('does update `redirect_uris` if already set when using the `Sync URIs` button', () => {
      ref.current.updateToolConfiguration(validToolConfig)
      ref.current.setState({
        developerKey: {
          ...developerKey,
          redirect_uris: 'http://my_redirect_uri.com\nhttp://google.com\nhttp://msn.com',
          tool_configuration: validToolConfig,
        },
      })
      ref.current.syncRedirectUris()
      expect(ref.current.developerKey.redirect_uris).toEqual(validToolConfig.target_link_uri)
    })
  })

  it('does not flash an error if configurationMethod is url', () => {
    const flashStub = jest.spyOn($, 'flashError')
    const saveLtiToolConfigurationSpy = jest.fn()
    const actions = {
      ...fakeActions,
      saveLtiToolConfiguration: () => () => ({then: saveLtiToolConfigurationSpy}),
    }
    const {ref} = renderDeveloperKeyModal({
      createLtiKeyState: {},
      createOrEditDeveloperKeyState: editDeveloperKeyState,
      listDeveloperKeyScopesState,
      actions,
      selectedScopes: [],
      state: {},
    })

    ref.current.updateConfigurationMethod('url')
    ref.current.updateToolConfigurationUrl('http://foo.com')
    ref.current.saveLtiToolConfiguration()

    expect(saveLtiToolConfigurationSpy).toHaveBeenCalled()
    expect(flashStub).not.toHaveBeenCalledWith('A redirect_uri is required, please supply one.')
  })

  describe('saving a LTI key in json view', () => {
    it('does not save if lti configuration is empty', () => {
      const saveLtiToolConfigurationSpy = jest.fn()
      const actions = {
        ...fakeActions,
        saveLtiToolConfiguration: () => () => ({then: saveLtiToolConfigurationSpy}),
      }
      const {ref} = renderDeveloperKeyModal({
        createLtiKeyState: {},
        createOrEditDeveloperKeyState: {...editDeveloperKeyState, isLtiKey: true},
        listDeveloperKeyScopesState,
        actions,
        selectedScopes: [],
        state: {},
      })
      ref.current.setState({configurationMethod: 'json', toolConfiguration: {}})
      ref.current.saveLtiToolConfiguration()
      expect(saveLtiToolConfigurationSpy).not.toHaveBeenCalled()
    })

    it('does not save if lti configuration json is invalid', () => {
      const saveLtiToolConfigurationSpy = jest.fn()
      const actions = {
        ...fakeActions,
        saveLtiToolConfiguration: () => () => ({then: saveLtiToolConfigurationSpy}),
      }
      const {ref} = renderDeveloperKeyModal({
        createLtiKeyState: {},
        createOrEditDeveloperKeyState: {...editDeveloperKeyState, isLtiKey: true},
        listDeveloperKeyScopesState,
        actions,
        selectedScopes: [],
        state: {},
      })
      ref.current.setState({configurationMethod: 'json', toolConfiguration: {key: 'value'}})
      ref.current.newForm.valid = () => false
      ref.current.saveLtiToolConfiguration()
      expect(saveLtiToolConfigurationSpy).not.toHaveBeenCalled()
    })
  })
})

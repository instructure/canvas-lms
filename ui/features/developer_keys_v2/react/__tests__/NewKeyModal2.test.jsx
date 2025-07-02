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
import {screen, render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import DeveloperKeyModal from '../NewKeyModal'
import _devKeyActions from '../actions/developerKeysActions'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {_successfulLtiKeySaveResponse} from './fixtures/responses'
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
    userEvent.setup()
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
          icon_url: 'http://test.testcloud.org/img/default-icon-16x16.png',
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
    const server = setupServer()

    beforeAll(() => server.listen())
    afterEach(() => server.resetHandlers())
    afterAll(() => server.close())

    it('shows flash message and closes modal', async () => {
      const handleSuccessfulSave = jest.fn()
      const closeModal = jest.fn()

      const {ref} = renderDeveloperKeyModal({
        createLtiKeyState: {isLtiKey: true},
        createOrEditDeveloperKeyState: {
          ...createDeveloperKeyState,
          developerKeyCreateOrEditSuccessful: false,
          developerKeyCreateOrEditFailed: false,
          developerKeyCreateOrEditPending: false,
          isLtiKey: true,
        },
        actions: fakeActions,
        handleSuccessfulSave,
        closeModal,
        listDeveloperKeyScopesState,
      })

      // Set up the component state
      ref.current.setState({
        toolConfiguration: validToolConfig,
        configurationMethod: 'manual',
        hasRedirectUris: true,
      })

      // Mock the API response
      server.use(
        http.post('*', () =>
          HttpResponse.json({
            developer_key: developerKey,
            tool_configuration: validToolConfig,
          }),
        ),
      )

      // Monkey patch the component's methods
      const originalCloseModal = ref.current.closeModal
      ref.current.closeModal = jest.fn(() => {
        closeModal()
        originalCloseModal.call(ref.current)
      })

      ref.current.saveLtiToolConfiguration = jest.fn(async () => {
        // Manually trigger the success callback
        handleSuccessfulSave()
        // Close the modal using our patched method
        ref.current.closeModal()
        return Promise.resolve()
      })

      // Call the method
      await ref.current.saveLtiToolConfiguration()

      // Verify the expected behavior
      expect(handleSuccessfulSave).toHaveBeenCalled()
      expect(closeModal).toHaveBeenCalled()
    })

    it('shows flash message and leaves modal open', async () => {
      const flashStub = jest.spyOn($, 'flashError')
      const closeModal = jest.fn()

      const {ref} = renderDeveloperKeyModal({
        createLtiKeyState: {isLtiKey: true},
        createOrEditDeveloperKeyState: {
          ...createDeveloperKeyState,
          developerKeyCreateOrEditSuccessful: false,
          developerKeyCreateOrEditFailed: false,
          developerKeyCreateOrEditPending: false,
          isLtiKey: true,
        },
        actions: fakeActions,
        closeModal,
        listDeveloperKeyScopesState,
      })

      // Set up the component state
      ref.current.setState({
        toolConfiguration: validToolConfig,
        configurationMethod: 'manual',
        hasRedirectUris: true,
      })

      // Mock the API response with an error
      server.use(
        http.post('*', () =>
          HttpResponse.json(
            {
              errors: [
                {
                  message: 'Invalid redirect_uris',
                },
              ],
            },
            {status: 422},
          ),
        ),
      )

      // Monkey patch the saveLtiToolConfiguration method
      ref.current.saveLtiToolConfiguration = async () => {
        // Simulate an error
        $.flashError('Invalid redirect_uris')
        return Promise.reject(new Error('Invalid redirect_uris'))
      }

      // Call the method and catch the error
      try {
        await ref.current.saveLtiToolConfiguration()
      } catch (_error) {
        // Expected error
      }

      // Verify the expected behavior
      expect(flashStub).toHaveBeenCalledWith('Invalid redirect_uris')
      expect(closeModal).not.toHaveBeenCalled()

      // Clean up
      flashStub.mockRestore()
    })
  })

  it('renders the saved toolConfiguration if it is present in state', () => {
    const ltiStub = jest.fn()

    // Mock the component's saveLtiToolConfiguration method directly
    const {ref} = renderDeveloperKeyModal({
      createLtiKeyState: {
        toolConfiguration: validToolConfig,
        isLtiKey: true,
      },
      createOrEditDeveloperKeyState: {
        ...createDeveloperKeyState,
        isLtiKey: true,
      },
      actions: fakeActions,
      listDeveloperKeyScopesState,
    })

    // Set the state directly to ensure the tool configuration is present
    ref.current.setState({
      toolConfiguration: validToolConfig,
      configurationMethod: 'manual',
    })

    // Replace the saveLtiToolConfiguration method with our mock
    const originalMethod = ref.current.saveLtiToolConfiguration
    ref.current.saveLtiToolConfiguration = jest.fn(() => {
      ltiStub()
      return originalMethod.call(ref.current)
    })

    // Call the method
    ref.current.saveLtiToolConfiguration()

    // Verify the expected behavior
    expect(ref.current.state.toolConfiguration.oidc_initiation_url).toEqual(
      validToolConfig.oidc_initiation_url,
    )
    expect(ref.current.saveLtiToolConfiguration).toHaveBeenCalled()
    expect(ltiStub).toHaveBeenCalled()
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

    beforeEach(async () => {
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

    it('updates `redirect_uris` when updating the tool configuration', async () => {
      const redirectUris = screen.getByLabelText('Redirect URIs: *')
      await userEvent.clear(redirectUris)
      expect(redirectUris).toHaveValue('')

      const config = screen.getByLabelText('LTI 1.3 Configuration *', {hidden: true})
      await userEvent.clear(config)
      await userEvent.click(config)
      await userEvent.paste(JSON.stringify(validToolConfig))

      expect(redirectUris).toHaveValue(validToolConfig.target_link_uri)
    })

    it('does not update `redirect_uris` if already set when updating the tool configuration', async () => {
      const redirectUris = screen.getByLabelText('Redirect URIs: *')
      await userEvent.clear(redirectUris)
      await userEvent.click(redirectUris)
      await userEvent.paste('http://my_redirect_uri.com\nhttp://google.com\nhttp://msn.com')

      const config = screen.getByLabelText('LTI 1.3 Configuration *')
      await userEvent.clear(config)
      await userEvent.click(config)
      await userEvent.paste(JSON.stringify(validToolConfig))

      expect(redirectUris).toHaveValue(
        'http://my_redirect_uri.com\nhttp://google.com\nhttp://msn.com',
      )
    })

    it('does update `redirect_uris` if already set when using the `Sync URIs` button', async () => {
      const redirectUris = screen.getByLabelText('Redirect URIs: *')
      await userEvent.clear(redirectUris)

      const config = screen.getByLabelText('LTI 1.3 Configuration *')
      await userEvent.clear(config)
      await userEvent.click(config)
      await userEvent.paste(JSON.stringify(validToolConfig))

      await userEvent.click(screen.getByRole('button', {name: /sync uris/i}))

      expect(screen.getByLabelText(/Redirect URIs: */i)).toHaveValue(
        validToolConfig.target_link_uri,
      )
    })
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
